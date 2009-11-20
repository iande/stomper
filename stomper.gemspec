Gem::Specification.new do |s|
  s.name = "stomper"
  s.version = "0.2.0"
  s.authors = ["Ian D. Eccles"]
  s.email = ["ian.eccles@gmali.com"]
  s.homepage = "http://github.com/iande/stomp"
  s.summary = "Ruby client for the stomp messaging protocol derived from the original stomp gem"
  s.description = s.summary
  s.platform = Gem::Platform::RUBY

  s.require_path = 'lib'
  s.executables = nil

  # get this easily and accurately by running 'Dir.glob("{lib,test}/**/*")'
  # in an IRB session.  However, GitHub won't allow that command hence
  # we spell it out.
  s.files = Dir.glob("{lib,spec}/**/*")
  s.test_files = Dir.glob("spec/**/*")
#  s.test_files = ["test/test_client.rb", "test/test_connection.rb", "test/test_helper.rb"]

  s.has_rdoc = true
  s.rdoc_options = ["--quiet", "--title", "stomp documentation", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source"]
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "LICENSE"]
end
  

