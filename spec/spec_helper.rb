#begin
#  require 'spec'
#rescue LoadError
#  require 'rubygems'
#  #gem 'rspec'
#  require 'spec'
#end
if RUBY_VERSION >= '1.9.0'
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require 'stomper'

