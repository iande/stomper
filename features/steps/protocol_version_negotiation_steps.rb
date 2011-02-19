When /^a connection is established$/ do
  @connection.connect
end

Given /^an unversioned Stomp broker$/ do
  @broker_uri_string = "stomp:///"
  @broker_uri = URI.parse(@broker_uri_string)
  @broker = TestStompServer.new(nil)
  @broker.start
  @connection = Stomper::Connection.new(@broker_uri)
end

When /^the client protocol version is "([^"]*)"$/ do |arg1|
  @connection.versions = arg1.split(",")
end
