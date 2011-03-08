After do |s|
  begin
    @connection && @connection.stop
  rescue Exception => ex
  end
  begin
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
    @sent_frames << f
  end
  @connection.after_receiving do |f, c|
    @received_frames << f
  end
  @connection.start
end

When /^the frame exchange is completed$/ do
  @connection.disconnect(:receipt => 'TERMINATE_POLITELY_12345')
  @connection.stop
  @broker.stop
end

When /^the frame exchange is completed without client disconnect$/ do
  @connection.stop
  @broker.stop
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

When /^the client protocol version is "([^"]*)"$/ do |arg1|
  @connection.versions = arg1.split(",")
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

Then /^the client should have received an? "([^"]*)" frame with headers$/ do |command, table|
  headers = table_to_headers table
  @received_frames.any? do |f|
    f.command == command && headers.all? { |(k,v)| headers[k] == f[k] }
  end.should be_true
end

When /^the client waits for (\d+) "([^"]*)" frames?$/ do |count, command|
  count = count.to_i
  Thread.pass while @received_frames.select { |f| f.command == command }.size < count
end

Given /^an established connection$/ do
  @connection.connect
end

When /^the client disconnects$/ do
  @connection.disconnect
  @broker.stop
end

Then /^after (\d+\.\d+) seconds, the receiver should no longer be running$/ do |sleep_for|
  sleep sleep_for.to_f
  @connection.running?.should be_false
end

When /^a connection is created for the SSL broker$/ do
  @connection = Stomper::Connection.new("stomp+ssl:///")
end

When /^the broker's host is "([^"]*)"$/ do |hostname|
  @connection.host = hostname
end

When /^no SSL verification is performed$/ do
  @connection.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
end

When /^SSL verification is performed$/ do
  @connection.ssl[:verify_mode] = ::OpenSSL::SSL::VERIFY_PEER | ::OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
end

When /^an SSL post connection check is performed on "([^"]*)"$/ do |host|
  @connection.ssl[:post_connection_check] = host
end

Then /^connecting should raise an openssl error$/ do
  lambda { @connection.connect }.should raise_error(OpenSSL::SSL::SSLError)
  # It is problematic that this is needed...
  @broker.stop
end

When /^an SSL post connection check is not performed$/ do
  @connection.ssl[:post_connection_check] = false
end

When /^the broker's certificate is verified by CA$/ do  
  @connection.ssl[:ca_file] = File.expand_path('../../support/ssl/demoCA/cacert.pem', __FILE__)
end

When /^the client's certificate and key are specified$/ do
  @connection.ssl[:cert] = OpenSSL::X509::Certificate.new(File.read(File.expand_path('../../support/ssl/client_cert.pem', __FILE__)))
  @connection.ssl[:key] = OpenSSL::PKey::RSA.new(File.read(File.expand_path('../../support/ssl/client_key.pem', __FILE__)))
end
