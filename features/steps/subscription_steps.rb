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

When /^the client subscribes to "([^"]*)" with headers within the scope$/ do |dest, table|
  @subscribe_frames ||= []
  headers = table_to_headers table
  @default_subscription_triggered = 0
  @subscribe_frames << @scope.subscribe(dest, headers) do |m|
    @default_subscription_triggered += 1
  end
end
