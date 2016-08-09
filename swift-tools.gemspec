Gem::Specification.new do |s|
  s.name = 'swift-tools'
  s.version = "3.2.0"
  s.summary = %q{Tools for managing Swift source code}
  s.description = %q{A suite of tools for managing and converting to Swift source code, including space/tab indentation, rough C# to Swift and Objective to Swift conversion.}
  s.authors = ["John Lyon-smith"]
  s.email = "john@jamoki.com"
  s.platform = Gem::Platform::RUBY
  s.license = "MIT"
  s.homepage = 'http://rubygems.org/gems/swift-tools'
  s.require_paths = ['lib']
  s.required_ruby_version = '~> 2.2'
  s.files = `git ls-files -- lib/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_runtime_dependency 'methadone', ['~> 1.9']
  s.add_development_dependency 'code-tools', ['~> 5.0']
end
