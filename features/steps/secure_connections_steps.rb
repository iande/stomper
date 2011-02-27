Given /^a Stomp (\d+\.\d+)?\s*SSL broker$/ do |version|
  @broker = TestSSLStompServer.new(version)
  @broker.start
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
