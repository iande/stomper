# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "stomper/version"

Gem::Specification.new do |s|
  s.name        = "stomper"
  s.version     = Stomper::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ian D. Eccles"]
  s.email       = ["ian.eccles@gmail.com"]
  s.homepage    = "http://github.com/iande/stomper"
  s.summary     = %q{Client for message queues implementing the Stomp protocol interface.}
  s.description = %q{Client library for message passing with brokers that support the Stomp protocol.}

  s.rubyforge_project = "stomper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  # Require Ruby 1.9 or better (needed for encoding support)
  # This MUST be adjusted to support 1.8.7 as well.
  s.required_ruby_version = '>= 1.9.0'
  s.has_rdoc = 'yard'
  s.add_development_dependency('rspec', '>= 2.0.0')
  s.add_development_dependency('simplecov', '>= 0.3.0')
  s.add_development_dependency('yard', '>= 0.6.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('bluecloth')
end
