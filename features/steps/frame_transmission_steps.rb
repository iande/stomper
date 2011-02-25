Then /^the broker should have received an? "([^"]*)" frame$/ do |command|
  Then "the broker should have received a \"#{command}\" frame with headers", table(%{
    | header-name | header-value |
  })
end

Then /^the broker should have received an? "([^"]*)" frame with headers$/ do |command, table|
  headers = table_to_headers table
  @broker.session.received_frames.any? do |f|
    f.command == command && headers.all? { |(k,v)| headers[k] == f[k] }
  end.should be_true
end

Then /^the client should have received an? "([^"]*)" frame with headers$/ do |command, table|
  headers = table_to_headers table
  @received_frames.any? do |f|
    f.command == command && headers.all? { |(k,v)| headers[k] == f[k] }
  end.should be_true
end

When /^the broker sends a "([^"]*)" frame with headers$/ do |command, table|
  headers = table_to_headers table
  @broker.session.send_frame command, headers
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

When /^the client waits for (\d+) "([^"]*)" frames?$/ do |count, command|
  count = count.to_i
  Thread.pass while @received_frames.select { |f| f.command == command }.size < count
end
