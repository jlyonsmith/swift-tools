module SwiftTools
  class ObjC2Swift

    def initialize
      @renamed_vars = {}
      @renamed_methods = {}
    end

    def execute(cs_file, swift_file, options)
      content = cs_file.read()

      # Things that clean up the code and make other regex's easier
      remove_eol_semicolons(content)

      swift_file.write(content)
    end

    def remove_eol_semicolons(content)
      content.gsub!(/; *$/m, '')
    end
  end
end
