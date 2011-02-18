$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__),"..","..","lib"))

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/features/"
  end
rescue LoadError
end

require 'stomper'
