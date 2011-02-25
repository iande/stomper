After do |s|
  begin
    @connection && @connection.stop
    @broker && @broker.force_stop
  rescue Exception => ex
  end
end

Given /^a (\d+\.\d+)?\s*connection between client and broker$/ do |version|
  version ||= '1.0'
  @broker_uri_string = "stomp:///"
  @broker_uri = URI.parse(@broker_uri_string)
  @broker = TestStompServer.new(version)
  @broker.start
  @connection = Stomper::Connection.new(@broker_uri)
  @received_frames = []
  @sent_frames = []
  @connection.before_transmitting do |f, c|
    #$stdout.puts "Sending frame: [#{f.command}] / #{f.headers.to_a.inspect}"
    @sent_frames << f
  end
  @connection.after_receiving do |f, c|
    #$stdout.puts "Received frame: [#{f.command}] / #{f.headers.to_a.inspect}"
    @received_frames << f
  end
  @connection.start
end


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

Then /^the (connection|client) should not be connected$/ do |arbitrary_name|
  @connection.connected?.should be_false
end

Then /^connecting should raise an connect failed error$/ do
  lambda { @connection.connect }.should raise_error(Stomper::Errors::ConnectFailedError)
end
