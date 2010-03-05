Gem::Specification.new do |s|
  s.name = "stomper"
  s.version = "0.3.2"
  s.authors = ["Ian D. Eccles"]
  s.email = ["ian.eccles@gmali.com"]
  s.homepage = "http://github.com/iande/stomper"
  s.summary = "Ruby client for the stomp messaging protocol derived from the original stomp gem"
  s.description = s.summary
  s.platform = Gem::Platform::RUBY

  s.require_path = 'lib'
  s.executables = nil

  s.files = Dir.glob("{lib,spec}/**/*")
  s.test_files = Dir.glob("spec/**/*")
#  s.test_files = ["test/test_client.rb", "test/test_connection.rb", "test/test_helper.rb"]

  s.has_rdoc = true
  s.rdoc_options = ["--quiet", "--title", "stomper documentation", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source"]
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "LICENSE", "AUTHORS"]
end
  

