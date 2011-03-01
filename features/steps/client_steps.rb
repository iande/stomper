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

When /^the client subscribes to "([^"]*)" with headers$/ do |dest, table|
  @subscribe_frames ||= []
  headers = table_to_headers table
  @default_subscription_triggered = 0
  @subscribe_frames << @connection.subscribe(dest, headers) do |m|
    @default_subscription_triggered += 1
  end
end

Then /^the default subscription callback should have been triggered( (\d+) times?)?$/ do |full, times|
  if times.nil? || times.empty?
    @default_subscription_triggered.should >= 1
  else
    @default_subscription_triggered.should == times.to_i
  end
end

Then /^the default subscription callback should not have been triggered$/ do
  @default_subscription_triggered.should == 0
end

When /^the client unsubscribes by ID$/ do
  @connection.unsubscribe(@subscribe_frames.last[:id])
end

When /^the client unsubscribes by destination$/ do
  @connection.unsubscribe(@subscribe_frames.last[:destination])
end

When /^the client unsubscribes by frame$/ do
  @connection.unsubscribe(@subscribe_frames.last)
end

When /^the client unsubscribes from destination "([^"]*)"$/ do |destination|
  @connection.unsubscribe(destination)
end

Given /^the client subscribes to (\/.*)$/ do |dest|
  @messages_for_subscription ||= []
  @connection.subscribe(dest) do |m|
    sub = m[:subscription]
    @messages_for_subscription << m
  end
end

When /^the client sends a "([^"]*)" "([^"]*)" to (\/.*)$/ do |ct, body, dest|
  @connection.send(dest, body, :'content-type' => ct)
end

Then /^the client should have received a "([^"]*)" message of "([^"]*)"$/ do |ct, body|
  @messages_for_subscription.any? do |m|
    m.content_type == ct && m.body == body
  end.should be_true
end

When /^the client sends a "([^"]*)" encoded as "([^"]*)" to (\/.*)$/ do |body, enc, dest|
  body.force_encoding(enc) if body.respond_to?(:force_encoding)
  @connection.send(dest, body)
end

Then /^the client should have received a "([^"]*)" message of "([^"]*)" encoded as "([^"]*)"$/ do |ct, body, enc|
  @messages_for_subscription.any? do |m|
    ct_check = (m.content_type == ct || m.content_type.nil? && ct.empty?)
    b_check = body == m.body
    if body.respond_to?(:encoding)
      ct_check && b_check && m.body.encoding.name == enc
    else
      ct_check && b_check
    end
  end.should be_true
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

Given /^a header scope with headers$/ do |table|
  headers = table_to_headers table
  @scope = @connection.with_headers(headers)
end

When /^the client acks a message by ID "([^"]*)" and subscription "([^"]*)" within the scope$/ do |message_id, subscription|
  @scope.ack message_id, subscription
end

When /^the client subscribes to "([^"]*)" with headers within the scope$/ do |dest, table|
  @subscribe_frames ||= []
  headers = table_to_headers table
  @default_subscription_triggered = 0
  @subscribe_frames << @scope.subscribe(dest, headers) do |m|
    @default_subscription_triggered += 1
  end
end

Given /^a transaction scope named "([^"]*)"$/ do |tx|
  @scope = @connection.with_transaction(:transaction => tx)
end

When /^the client begins the transaction scope$/ do
  @scope.begin
end

When /^the client nacks a message by ID "([^"]*)" and subscription "([^"]*)" within the scope$/ do |message_id, subscription|
  @scope.nack message_id, subscription
end

When /^the client aborts the transaction scope$/ do
  @scope.abort
end

When /^the client executes a successful transaction block named "([^"]*)"$/ do |tx|
  @connection.with_transaction(:transaction => tx) do |t|
    t.ack "message-id", "subscription-id"
    t.send "/queue/transaction/test", "message"
    t.nack "message-id-2", "subscription-id-2"
  end
end

When /^the client executes an unsuccessful transaction block named "([^"]*)"$/ do |tx|
  lambda do
    @connection.with_transaction(:transaction => tx) do |t|
      t.ack "message-id", "subscription-id"
      t.send "/queue/transaction/test", "message"
      t.nack "message-id-2", "subscription-id-2"
      raise "transaction will now fail"
    end
  end.should raise_error("transaction will now fail")
end

When /^the client sends a receipted message "([^"]*)" to "([^"]*)"$/ do |body, destination|
  @connection.send(destination, body) do |r|
  end
end

Then /^the client should have received a receipt for the last "([^"]*)"$/ do |command|
  fr = @sent_frames.select { |f| f.command == command }.last
  r = @received_frames.select { |f| f.command == 'RECEIPT' && f[:'receipt-id'] == fr[:receipt] }.last
  r.should_not be_nil
end

When /^the client subscribes to "([^"]*)" with a receipt$/ do |destination|
  @connection.with_receipt do |r|
  end.subscribe(destination)
end

When /^the client unsubscribes from "([^"]*)" with a receipt$/ do |subscription|
  @connection.with_receipt do |r|
  end.unsubscribe(subscription)
end

When /^the client begins transaction "([^"]*)" with a receipt$/ do |tx|
  @connection.with_receipt do |r|
  end.begin(tx)
end

When /^the client aborts transaction "([^"]*)" with a receipt$/ do |tx|
  @connection.with_receipt do |r|
  end.abort(tx)
end

When /^the client commits transaction "([^"]*)" with a receipt$/ do |tx|
  @connection.with_receipt do |r|
  end.commit(tx)
end

When /^the client acks message "([^"]*)" from "([^"]*)" with a receipt$/ do |m_id, sub_id|
  @connection.with_receipt do |r|
  end.ack(m_id, sub_id)
end

When /^the client nacks message "([^"]*)" from "([^"]*)" with a receipt$/ do |m_id, sub_id|
  @connection.with_receipt do |r|
  end.nack(m_id, sub_id)
end

When /^the client disconnects with a receipt$/ do
  @connection.with_receipt do |r|
  end.disconnect
end

When /^the client connects with a receipt$/ do
  @connection.with_receipt do |r|
  end.transmit(Stomper::Frame.new('CONNECT'))
end

Then /^the client should not have added a receipt header to the last "([^"]*)"$/ do |command|
  fr = @sent_frames.select { |f| f.command == command }.last
  fr[:receipt].should be_nil
end

When /^the client acks a message by ID "([^"]*)"$/ do |message_id|
  @connection.ack message_id
end

When /^the client acks the last MESSAGE$/ do
  When("the client waits for 1 \"MESSAGE\" frame")
  @connection.ack @received_frames.select { |f| f.command == "MESSAGE" }.last
end

Then /^the client nacking the last MESSAGE should raise an unsupported command error$/ do
  lambda { @connection.nack @received_frames.select { |f| f.command == "MESSAGE" }.last }.should raise_error(Stomper::Errors::UnsupportedCommandError)
end

When /^the client acks a message by ID "([^"]*)" and subscription "([^"]*)"$/ do |message_id, subscription|
  @connection.ack message_id, subscription
end

When /^the client nacks the last MESSAGE$/ do
  When("the client waits for 1 \"MESSAGE\" frame")
  @connection.nack @received_frames.select { |f| f.command == "MESSAGE" }.last
end

When /^the client nacks a message by ID "([^"]*)" and subscription "([^"]*)"$/ do |message_id, subscription|
  @connection.nack message_id, subscription
end

Then /^the client acking a message by ID "([^"]*)" should raise an argument error$/ do |message_id|
  lambda { @connection.ack message_id }.should raise_error(ArgumentError)
end

Then /^the client nacking a message by ID "([^"]*)" should raise an argument error$/ do |message_id|
  lambda { @connection.nack message_id }.should raise_error(ArgumentError)
end

Then /^the client acking the last MESSAGE should raise an argument error$/ do
  lambda { @connection.ack @received_frames.select { |f| f.command == "MESSAGE" }.last }.should raise_error(ArgumentError)
end

Then /^the client nacking the last MESSAGE should raise an argument error$/ do
  lambda { @connection.nack @received_frames.select { |f| f.command == "MESSAGE" }.last }.should raise_error(ArgumentError)
end
