module SwiftTools
  class ObjC2Swift

    INDENT = '    '

    def initialize
    end

    def execute(h_file, m_file, swift_file, options)
      hdr_content = h_file.read()
      h_filename = File.basename(h_file.to_path)

      imports = capture_imports(h_filename, hdr_content)
      statics = capture_statics(hdr_content, in_hdr = true)
      interfaces = capture_interfaces(hdr_content, in_hdr = true)
      copyright = capture_copyright(hdr_content)

      unless m_file.nil?
        impl_content = m_file.read()
        impl_imports = capture_imports(h_filename, impl_content)
        impl_interfaces = capture_interfaces(impl_content, in_hdr = false)
        impl_statics = capture_statics(impl_content, in_hdr = false)
      end

      # Add copyright
      unless copyright.nil?
        swift_file.write("//\n#{copyright}\n//\n\n")
      end

      # Combine all the imports
      swift_file.write(imports[:at_imports])
      swift_file.write(impl_imports[:at_imports]) unless impl_imports.nil?
      swift_file.write(imports[:hash_imports])
      swift_file.write(impl_imports[:hash_imports]) unless impl_imports.nil?
      swift_file.write("\n")

      # Combine interfaces
      unless impl_interfaces.nil?
        impl_interfaces.each { |name, data|
          hdr_has_interface = interfaces.include?(name)
          interfaces[name][:properties].merge!(data[:properties]) if hdr_has_interface
          interfaces[name][:methods].merge!(data[:methods]) { |key, v1, v2|
            {
                :scope => v2[:scope],
                :return_type => v2[:return_type],
                :visibility => v1[:visibility],
                :body => v2[:body]
            }
          } if hdr_has_interface
        }
      end

      # Output classes or extensions from interfaces
      interfaces.each {|interface_name, interface_data|
        swift_file.write("@objc class #{interface_name}")
        if interface_data[:base] != nil
          swift_file.write(": #{interface_data[:base]}")
        end
        if interface_data[:protocols] != nil
          swift_file.write(", #{interface_data[:protocols]}")
        end
        swift_file.write("{\n")

        # Create Swift singletons
        if interface_data[:methods].include?('sharedInstance')
          interface_data[:methods].delete('sharedInstance')
          interface_data[:properties]['sharedInstance'] = {
              :const => true,
              :visibility => :public,
              :scope => :static,
              :initializer => "#{interface_name}()"
          }
          interface_data[:inits].push({
              body: '',
              :visibility => :private
          })
        end

        # Add getter props
        new_properties = {}
        interface_data[:properties].each {|prop_name, prop_data|
          if prop_data[:getter]
            new_properties[prop_data[:getter]] = {
                :visibility => :public,
                :type => 'Bool',
                :scope => prop_data[:scope],
                :body => "return #{prop_name}"
            }

            # Remove :readonly if set and make private
            prop_data.delete(:readonly)
            prop_data[:visibility] = :private
          end
        }
        interface_data[:properties].merge!(new_properties)

        # line2 = INDENT + "public var #{prop_data[:getter]}: #{prop_data[:type]} { return #{prop_name} }\n"
        # if prop_data[:getter]
        #   line1 = INDENT + "private "

        # Write properties
        interface_data[:properties].each {|prop_name, prop_data|
          line = INDENT
          if prop_data[:readonly]
            line += "private(set) public "
          elsif prop_data[:visibility] == :private
            line += 'private '
          end

          if prop_data[:scope] == :static
            line += "static "
          end

          if prop_data[:weak]
            line += 'weak '
          end

          if prop_data[:const]
            line += 'let '
          else
            line += 'var '
          end

          line += "#{prop_name}"

          if prop_data[:type]
            line += ": #{prop_data[:type]}"
          end

          if prop_data[:initializer]
            line += " = #{prop_data[:initializer]}"
          end

          if prop_data[:body]
            line += " {\n" + INDENT + INDENT + prop_data[:body] + "\n" + INDENT + "}"
          end

          line += "\n"

          swift_file.write(line)
        }

        # Write inits
        interface_data[:inits].each {|init_data|
          line = "\n" + INDENT

          if init_data[:visibility] == :private
            line += 'private '
          end

          line += "init() {"

          if init_data[:body].length > 0
            line += "\n" + body + "\n"
          end

          line += "}\n"
          swift_file.write(line)
        }

        # Write methods
        interface_data[:methods].each {|method_name, method_data|
          line = "\n" + INDENT

          if method_data[:visibility] == :private
            line += 'private '
          end

          line += "func #{method_name}()"
          if method_data[:return_type] and method_data[:return_type] != 'Void'
            line += " -> #{method_data[:return_type]}"
          end

          line += ' {'

          if method_data[:body].strip.length == 0
            line += "}\n"
          else
            line += method_data[:body] + INDENT + "}\n"
          end

          swift_file.write(line)
        }

        swift_file.write("}\n")
      }
    end

    def capture_copyright(content)
      copyright = nil
      content.match(/^\s*\/\/.*Copyright.*$/) {|m|
        copyright = m[0]
      }
      copyright
    end

    def capture_imports(h_filename, content)
      r1 = ''
      r2 = ''
      content.scan(/[@#]import\s*"?[\.a-zA-Z0-9_]+"?\s*;?\s*\n?/m).each {|m|
        s = m.strip
        if s.start_with?("#")
          if s.index(h_filename).nil?
            r2 += "// TODO: Add '#{s}' to bridging header\n"
          end
        else
          r1 += remove_eol_semicolons(s) + "\n"
        end
      }
      {:at_imports => r1, :hash_imports => r2}
    end

    def capture_interfaces(content, in_hdr)
      interfaces = {}
      content.scan(/^\s*@interface\s*([a-zA-Z0-9_]+)(?:\s*:\s*([a-zA-Z0-9_]+)\s*)?(?:\s*\(([a-zA-Z0-9_, ]*)\))?(?:\s*<(.+)>)?((?:.|\n)*)@end\s*\n$/m).each {|m|
        body = m[4]
        remove_eol_semicolons(body)
        methods = extract_methods(body, in_hdr)
        properties = extract_properties(body, in_hdr)

        interfaces[m[0]] = {
          :base => m[1],
          :categories => m[2] == '' ? nil : m[2],
          :protocols => m[3],
          :properties => properties,
          :methods => methods,
          :inits => []
        }
      }
      interfaces
    end

    def extract_properties(content, in_hdr)
      properties = {}
      content.scan(/^\s*@property\s*\(([a-zA-Z0-9_=, ]*)\)\s*([a-zA-Z0-9_\*]+)\s*([a-zA-Z0-9_\*]+)\s*$/m) {|m|
        name = $3
        type = map_type($2)
        options = Hash[$1.split(',').map(&:strip).collect {|s|
          a = s.split('=')
          if a.length > 1
            [a[0].to_sym, a[1]]
          else
            [a[0].to_sym, true]
          end
        }]
        properties[name.gsub('*', '')] = {
            :type => type,
            :visibility => in_hdr ? :public : :private,
            :scope => :instance
        }.merge(options)
      }
      properties
    end

    def extract_methods(content, in_hdr)
      methods = {}
      content.to_enum(:scan, /^ *(\+|-)? *\(([a-zA-Z0-9_]+)\) *([a-zA-Z0-9_]+)(?:[ \n]*\{)?/m).map { Regexp.last_match }.each {|m|
        if in_hdr
          body = ''
        else
          body_start_offset = m.offset(0)[1]
          body_end_offset = find_close_char_offset(content, body_start_offset, '{', '}') - 1
          body = indent_lines(content[body_start_offset..body_end_offset])
        end
        methods[m[3]] = {
          :scope => (m[1] == '+' ? :static : :instance),
          :return_type => map_type(m[2]),
          :visibility => in_hdr ? :public : :private,
          :body => body
        }
      }
      methods
    end

    def capture_implementation(content)
      content.scan(/@implementation(?:.|\n)*@end\s*\n/m)
    end

    def capture_statics(content, in_hdr)
      content.scan(/static.*;\s*\n/m)
    end

    def remove_eol_semicolons(content)
      content.gsub!(/; *$/m, '')
    end

    def find_close_char_offset(content, offset, open_char, close_char)
      count = 1
      loop do
        if offset >= content.length
          raise "Ran out of content looking for #{close_char}"
        elsif content[offset] == close_char
          count -= 1
          if count == 0
            break
          end
        elsif content[offset] == open_char
          count += 1
        end
        offset += 1
      end
      offset
    end

    def indent_lines(content)
      s = ''
      content.each_line {|line|
        s += INDENT + line
      }
      s
    end

    def map_type(content)
      # Remove C pointer marker if present
      content.gsub!('*', '')

      case content
      when 'BOOL'
        'Bool'
      when 'int'
        'Int'
      when 'uint'
        'UInt'
      when 'long'
        'Long'
      when 'void'
        'Void'
      when /(.*)\*/
        $1
      else
        content
      end
    end
  end
end
