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