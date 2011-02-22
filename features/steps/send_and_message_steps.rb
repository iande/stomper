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

