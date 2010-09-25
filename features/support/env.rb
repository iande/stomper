$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__),"..","..","lib"))
require 'stomper'
begin
  require 'rspec/expectations'
rescue LoadError
  require 'spec/expectations'
end
