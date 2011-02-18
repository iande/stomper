After do |s|
  destroy_broker
end

Given /^a Stomp (\d+\.\d+) broker$/ do |version|
  @broker_uri_string = "stomp:///"
  @broker_uri = URI.parse(@broker_uri_string)
  create_broker(version)
  @connection = Stomper::Connection.new(@broker_uri)
end

Given /^an erroring Stomp broker$/ do
  @broker_uri_string = "stomp:///"
  @broker_uri = URI.parse(@broker_uri_string)
  create_error_broker
  @connection = Stomper::Connection.new(@broker_uri)
end


When /^a connection is created from the broker's URI$/ do
  #@connection = Stomper::Connection.new(@broker_uri)
end

When /^a connection is created from the broker's URI string$/ do
  @connection = Stomper::Connection.new(@broker_uri_string)
end

When /^the connection is told to connect$/ do
  @connection.connect
end

Then /^the connection should be connected$/ do
  @connection.connected?.should be_true
end

Then /^the connection should be using the (\d+\.\d+) protocol$/ do |version|
  @connection.version.should == version
end

Then /^connecting should raise an unsupported protocol version error$/ do
  lambda { @connection.connect }.should raise_error(Stomper::Errors::UnsupportedProtocolVersionError)
end

Then /^the connection should not be connected$/ do
  @connection.connected?.should be_false
end

Then /^connecting should raise an connect failed error$/ do
  lambda { @connection.connect }.should raise_error(Stomper::Errors::ConnectFailedError)
end
