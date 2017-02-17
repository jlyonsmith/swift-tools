require 'swift_tools/core_ext.rb'

module SwiftTools
  class Csharp2Swift

    attr_reader :renamed_vars
    attr_reader :renamed_methods

    def initialize
      @renamed_methods = {}
      @renamed_vars = {}
    end

    def execute(cs_file, swift_file, options)
      content = cs_file.read()

      # Things that clean up the code and make other regex's easier
      remove_eol_semicolons(content)
      join_open_brace_to_last_line(content)
      remove_region(content)
      remove_endregion(content)
      remove_namespace_using(content)
      convert_this_to_self(content)
      convert_int_type(content)
      convert_string_type(content)
      convert_bool_type(content)
      convert_float_type(content)
      convert_double_type(content)
      convert_list_list_type(content)
      convert_list_array_type(content)
      convert_list_type(content)
      convert_debug_assert(content)
      remove_new(content)
      insert_import(content)

      # Slightly more complicated stuff
      remove_namespace(content)
      convert_property(content)
      remove_get_set(content)
      convert_const_field(content)
      convert_field(content)
      constructors_to_inits(content)
      convert_method_decl_to_func_decl(content)
      convert_locals(content)
      convert_if(content)
      convert_next_line_else(content)
      convert_simple_range_for_loop(content)

      # Global search/replace
      @renamed_vars.each { |v, nv|
        content.gsub!(Regexp.new("\\." + v + "\\b"), '.' + nv)
      }
      @renamed_methods.each { |m, nm|
        content.gsub!(Regexp.new('\\b' + m + '\\('), nm + '(')
      }

      swift_file.write(content)
    end

    def remove_eol_semicolons(content)
      content.gsub!(/; *$/m, '')
    end

    def join_open_brace_to_last_line(content)
      re = / *\{$/m
      m = re.match(content)
      s = ' {'

      while m != nil do
        offset = m.offset(0)
        start = offset[0]
        content.slice!(offset[0]..offset[1])
        content.insert(start - 1, s)
        m = re.match(content, start - 1 + s.length)
      end
    end

    def convert_this_to_self(content)
      content.gsub!(/this\./, 'self.')
    end

    def remove_region(content)
      content.gsub!(/ *#region.*\n/, '')
    end

    def remove_endregion(content)
      content.gsub!(/ *#endregion.*\n/, '')
    end

    def remove_namespace_using(content)
      content.gsub!(/ *using (?!\().*\n/, '')
    end

    def convert_int_type(content)
      content.gsub!(/\bint\b/, 'Int')
    end

    def convert_string_type(content)
      content.gsub!(/\bstring\b/, 'Int')
    end

    def convert_bool_type(content)
      content.gsub!(/\bbool\b/, 'Bool')
    end

    def convert_float_type(content)
      content.gsub!(/\bfloat\b/, 'Float')
    end

    def convert_double_type(content)
      content.gsub!(/\bdouble\b/, 'Double')
    end

    def convert_list_type(content)
      content.gsub!(/(?:List|IList)<(\w+)>/, '[\\1]')
    end

    def convert_list_list_type(content)
      content.gsub!(/(?:List|IList)<(?:List|IList)<(\w+)>>/, '[[\\1]]')
    end

    def convert_list_array_type(content)
      content.gsub!(/(?:List|IList)<(\w+)>\[\]/, '[[\\1]]')
    end

    def convert_debug_assert(content)
      content.gsub!(/Debug\.Assert\(/, 'assert(')
    end

    def remove_new(content)
      content.gsub!(/new /, '')
    end

    def insert_import(content)
      content.insert(0, "import Foundation\n")
    end

    def remove_namespace(content)
      re = / *namespace +.+ *\{$/
      m = re.match(content)

      if m == nil
        return
      end

      i = m.end(0)
      n = 1
      bol = (content[i] == "\n")
      while i < content.length do
        c = content[i]

        if bol and c == " " and i + 3 < content.length
          content.slice!(i..(i + 3))
          c = content[i]
        end

        case c
          when "{"
            n += 1
          when "}"
            n -= 1
            if n == 0
              content.slice!(i) # Take out the end curly
              content.slice!(m.begin(0)..m.end(0)) # Take out the original namespace
              break
            end
          when "\n"
            bol = true
          else
            bol = false
        end
        i += 1
      end
    end

    def convert_const_field(content)
      content.gsub!(/(^ *)(?:public|private|internal) +const +(.+?) +(.+?)( *= *.*?|)$/) { |m|
        v = $3
        nv = v.lower_camelcase
        @renamed_vars[v] = nv
        $1 + 'let ' + nv + ': ' + $2 + $4
      }
    end

    def convert_field(content)
      content.gsub!(/(^ *)(?:public|private|internal) +(\w+) +(\w+)( *= *.*?|)$/) { |m|
        $1 + 'private var ' + $3 + ': ' + $2 + $4
      }
    end

    def convert_property(content)
      content.gsub!(/(^ *)(?:public|private|internal) +(?!class)([A-Za-z0-9_\[\]<>]+) +(\w+)(?: *\{)/) { |m|
        v = $3
        nv = v.lower_camelcase
        @renamed_vars[v] = nv
        $1 + 'var ' + nv + ': ' + $2 + ' {'
      }
    end

    def remove_get_set(content)
      content.gsub!(/{ *get; *set; *}$/, '')
    end

    def constructors_to_inits(content)
      re = /(?:(?:public|internal|private) +|)class +(\w+)/
      m = re.match(content)
      while m != nil do
        content.gsub!(Regexp.new('(?:(?:public|internal) +|)' + m.captures[0] + " *\\("), 'init(')
        m = re.match(content, m.end(0))
      end

      content.gsub!(/init\((.*)\)/) { |m|
        'init(' + swap_args($1) + ')'
      }
    end

    def convert_method_decl_to_func_decl(content)
      # TODO: Override should be captured and re-inserted
      content.gsub!(/(?:(?:public|internal|private) +)(?:override +|)(.+) +(.*)\((.*)\) *\{/) { |m|
        f = $2
        nf = f.lower_camelcase
        @renamed_methods[f] = nf
        if $1 == "void"
          'func ' + nf + '(' + swap_args($3) + ') {'
        else
          'func ' + nf + '(' + swap_args($3) + ') -> ' + $1 + ' {'
        end
      }
    end

    def convert_locals(content)
      content.gsub!(/^( *)(?!return|import)([A-Za-z0-9_\[\]<>]+) +(\w+)(?:( *= *.+)|)$/, '\\1let \\3\\4')
    end

    def convert_if(content)
      content.gsub!(/if *\((.*)\) +\{/, 'if \\1 {')
      content.gsub!(/if *\((.*?)\)\n( +)(.*?)\n/m) { |m|
        s = $2.length > 4 ? $2[0...-4] : s
        'if ' + $1 + " {\n" + $2 + $3 + "\n" + s + "}\n"
      }
    end

    def convert_next_line_else(content)
      content.gsub!(/\}\n +else \{/m, '} else {')
    end

    def convert_simple_range_for_loop(content)
      content.gsub!(/for \(.+ +(\w+) = (.+); \1 < (.*); \1\+\+\)/, 'for \\1 in \\2..<\\3')
      content.gsub!(/for \(.+ +(\w+) = (.+); \1 >= (.*); \1\-\-\)/, 'for \\1 in (\\3...\\2).reverse()')
    end

    def swap_args(arg_string)
      args = arg_string.split(/, */)
      args.collect! { |arg|
        a = arg.split(' ')
        a[1] + ': ' + a[0]
      }
      args.join(', ')
    end

    def read_file(filename)
      content = nil
      File.open(filename, 'rb') { |f| content = f.read() }
      content
    end

    def write_file(filename, content)
      File.open(filename, 'w') { |f| f.write(content) }
    end

    def error(msg)
      STDERR.puts "error: #{msg}".red
    end

  end
end
