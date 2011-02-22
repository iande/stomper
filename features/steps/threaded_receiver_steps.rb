When /^the broker closes the connection unexpectedly$/ do
  @broker.force_stop
end

Then /^after (\d+\.\d+) seconds, the receiver should no longer be running$/ do |sleep_for|
  sleep sleep_for.to_f
  @connection.running?.should be_false
end
