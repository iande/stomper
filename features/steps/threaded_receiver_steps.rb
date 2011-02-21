When /^the broker closes the connection unexpectedly$/ do
  @broker.force_stop
end

Then /^the receiver should no longer be running$/ do
  @connection.running?.should be_false
end
