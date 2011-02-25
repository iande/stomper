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