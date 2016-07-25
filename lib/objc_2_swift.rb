module SwiftTools
  class ObjC2Swift

    def initialize
      @renamed_vars = {}
      @renamed_methods = {}
    end

    def execute(h_file, m_file, swift_file, options)
      hdr_content = h_file.read()

      hdr_imports = extract_imports(hdr_content)
      hdr_statics = extract_statics(hdr_content)
      hdr_interface = extract_interface(hdr_content)

      unless m_file.nil?
        impl_content += m_file.read()
        impl_imports = extract_imports(impl_content)
        impl_statics = e
      end

      # Delay doing this to make other regex's easier
      remove_eol_semicolons(content)

      swift_file.write(content)
    end

    def remove_eol_semicolons(content)
      content.gsub!(/; *$/m, '')
    end
  end
end
