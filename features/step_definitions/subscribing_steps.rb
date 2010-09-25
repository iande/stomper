Given /^I am connected to "([^\"]*)"$/ do |uri|
  @consumer = Stomper::Connection.open(uri)
end

Given /^I am subscribed to "([^\"]*)"$/ do |destination|
  @incoming_subscription_messages = []
  @consumer.subscribe(destination) do |msg|
    @incoming_subscription_messages << msg
  end
end

Given /^a producer exists for "([^\"]*)"$/ do |uri|
  @producer = Stomper::Connection.open(uri)
end

When /^a producer sends "([^\"]*)" to "([^\"]*)"$/ do |body, destination|
  @producer.send(destination, body)
end

When /^I receive a frame$/ do
  @consumer.receive
end

Then /^the frame's headers should include "([^\"]*)" paired with "([^\"]*)"$/ do |key, val|
  key = key.to_sym
  @incoming_subscription_messages.last.headers.has_key?(key).should be_true
  @incoming_subscription_messages.last.headers[key].should == val
end

Then /^the frame's body should be "([^\"]*)"$/ do |body|
  @incoming_subscription_messages.last.body.should == body
end
