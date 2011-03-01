When /^the client sends a receipted message "([^"]*)" to "([^"]*)"$/ do |body, destination|
  @connection.send(destination, body) do |r|
  end
end

Then /^the client should have received a receipt for the last "([^"]*)"$/ do |command|
  fr = @sent_frames.select { |f| f.command == command }.last
  r = @received_frames.select { |f| f.command == 'RECEIPT' && f[:'receipt-id'] == fr[:receipt] }.last
  r.should_not be_nil
end

When /^the client subscribes to "([^"]*)" with a receipt$/ do |destination|
  @connection.with_receipt do |r|
  end.subscribe(destination)
end

When /^the client unsubscribes from "([^"]*)" with a receipt$/ do |subscription|
  @connection.with_receipt do |r|
  end.unsubscribe(subscription)
end

When /^the client begins transaction "([^"]*)" with a receipt$/ do |tx|
  @connection.with_receipt do |r|
  end.begin(tx)
end

When /^the client aborts transaction "([^"]*)" with a receipt$/ do |tx|
  @connection.with_receipt do |r|
  end.abort(tx)
end

When /^the client commits transaction "([^"]*)" with a receipt$/ do |tx|
  @connection.with_receipt do |r|
  end.commit(tx)
end

When /^the client acks message "([^"]*)" from "([^"]*)" with a receipt$/ do |m_id, sub_id|
  @connection.with_receipt do |r|
  end.ack(m_id, sub_id)
end

When /^the client nacks message "([^"]*)" from "([^"]*)" with a receipt$/ do |m_id, sub_id|
  @connection.with_receipt do |r|
  end.nack(m_id, sub_id)
end

When /^the client disconnects with a receipt$/ do
  @connection.with_receipt do |r|
  end.disconnect
end

When /^the client connects with a receipt$/ do
  @connection.with_receipt do |r|
  end.transmit(Stomper::Frame.new('CONNECT'))
end

Then /^the client should not have added a receipt header to the last "([^"]*)"$/ do |command|
  fr = @sent_frames.select { |f| f.command == command }.last
  fr[:receipt].should be_nil
end
