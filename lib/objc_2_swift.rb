module SwiftTools
  class ObjC2Swift

    def initialize
      @renamed_vars = {}
      @renamed_methods = {}
    end

    def execute(h_file, m_file, swift_file, options)
      hdr_content = h_file.read()
      h_filename = File.basename(h_file.to_path)

      hdr_imports = capture_imports(h_filename, hdr_content)
      hdr_statics = capture_statics(hdr_content)
      classes = capture_hdr_interface(hdr_content)

      unless m_file.nil?
        impl_content = m_file.read()
        impl_imports = capture_imports(h_filename, impl_content)
        #impl_statics = capture_interface(impl_content)
      else
        impl_imports = {:at_imports => '', :hash_imports => ''}
        impl_statics = nil
      end

      swift_file.write("//\n//  Copyright (c) 2015 RealSelf. All rights reserved.\n//\n\n")

      # Combine all the imports, process and write out
      swift_file.write(hdr_imports[:at_imports] + impl_imports[:at_imports])
      swift_file.write(hdr_imports[:hash_imports] + impl_imports[:hash_imports])
      swift_file.write("\n")

      # Output classes from interfaces
      classes.each {|name, data|
        swift_file.write("@objc class #{name}")
        if data[:base_name] != nil
          swift_file.write(": #{data[:base_name]}")
        end
        if data[:protocols] != nil
          swift_file.write(", #{data[:protocols]}")
        end
        swift_file.write(" {\n#{data[:body]}}\n")
      }

      # Delay doing this to make other regex's easier
      #remove_eol_semicolons(content)

      #swift_file.write(content)
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

    def capture_hdr_interface(content)
      classes = {}
      content.scan(/@interface\s*([a-zA-Z0-9_]+)(?:\s*:\s*)?([a-zA-Z0-9_]+)?(?:\s*<)?([a-zA-Z0-9_, ]+)?(?:>)?((?:.|\n)*)@end\s*\n/m).each {|m|
        body = indent_lines(m[3])
        remove_eol_semicolons(body)
        replace_properties(body)

        classes[m[0]] = {
          :base_name => m[1],
          :protocols => m[2],
          :body => body,
        }
      }
      classes
    end

    def capture_implementation(content)
      content.scan(/@implementation(?:.|\n)*@end\s*\n/m)
    end

    def capture_statics(content)
      content.scan(/static.*;\s*\n/m)
    end

    def remove_eol_semicolons(content)
      content.gsub!(/; *$/m, '')
    end

    def indent_lines(content)
      s = ''
      content.each_line {|line|
        s += "\t" + line.strip + "\n"
      }
      s
    end

    def replace_properties(content)
      content.gsub!(/^\s*@property\s*\(([a-zA-Z0-9_=, ]+)\)\s*([a-zA-Z0-9_\*]+)\s*([a-zA-Z0-9_]+)\s*\n/m) {|m|
        line1 = "\t"
        line2 = ''
        name = $3
        type = map_type($2)
        options = Hash[$1.split(',').map(&:strip).collect {|s|
          a = s.split('=')
          if a.length > 1
            [a[0], a[1]]
          else
            [a[0], true]
          end
        }]
        if options['readonly']
          if options['getter']
            line1 += "private "
            line2 += "\tvar #{options['getter']}: #{type} { return #{name} }\n"
          else
            line1 += "private(set) "
          end
        end
        if options['weak']
          line1 += "weak "
        end
        line1 += "var #{name}: #{type}\n"
        line1 + line2
      }
    end

    def map_type(content)
      case content
      when 'BOOL'
        'Bool'
      when 'int'
        'Int'
      when 'uint'
        'UInt'
      when 'long'
        'Long'
      when /(.*)\*/
        $1
      else
        content
      end
    end
  end
end
