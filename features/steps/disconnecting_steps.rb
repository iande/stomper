Given /^an established connection$/ do
  @connection.connect
end

When /^the client disconnects$/ do
  @connection.disconnect
  @broker.stop
end
