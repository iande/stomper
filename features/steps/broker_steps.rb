Given /^a Stomp (\d+\.\d+)?\s*broker$/ do |version|
  version ||= '1.0'
  @broker_uri_string = "stomp:///"
  @broker_uri = URI.parse(@broker_uri_string)
  @broker = TestStompServer.new(version)
  @broker.start
  @connection = Stomper::Connection.new(@broker_uri)
end

Given /^an erroring Stomp broker$/ do
  @broker_uri_string = "stomp:///"
  @broker_uri = URI.parse(@broker_uri_string)
  @broker = TestStompServer.new('1.0')
  @broker.session_class = TestStompServer::StompErrorOnConnectSession
  @broker.start
  @connection = Stomper::Connection.new(@broker_uri)
end

Then /^the broker should have received an? "([^"]*)" frame$/ do |command|
  Then "the broker should have received a \"#{command}\" frame with headers", table(%{
    | header-name | header-value |
  })
end

Then /^the broker should have received an? "([^"]*)" frame with headers$/ do |command, table|
  headers = table_to_headers table
  @broker.session.received_frames.any? do |f|
    f.command == command && headers.all? { |(k,v)| headers[k] == f[k] }
  end.should be_true
end

When /^the broker sends a "([^"]*)" frame with headers$/ do |command, table|
  headers = table_to_headers table
  @broker.session.send_frame command, headers
end

When /^the broker closes the connection unexpectedly$/ do
  @broker.force_stop
end

Given /^a Stomp (\d+\.\d+)?\s*SSL broker$/ do |version|
  @broker = TestSSLStompServer.new(version)
  @broker.start
end

Given /^an unversioned Stomp broker$/ do
  @broker_uri_string = "stomp:///"
  @broker_uri = URI.parse(@broker_uri_string)
  @broker = TestStompServer.new(nil)
  @broker.start
  @connection = Stomper::Connection.new(@broker_uri)
end
