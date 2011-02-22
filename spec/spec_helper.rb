# -*- encoding: utf-8 -*-
Dir[File.expand_path('support', File.dirname(__FILE__)) + "/**/*.rb"].each { |f| require f }

if RUBY_VERSION < '1.9'
  class Symbol
    def <=>(other)
      self.to_s <=> other.to_s
    end
  end
end

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError
end

require 'stomper'
