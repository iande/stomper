When /^the client sends a receipted message "([^"]*)" to "([^"]*)"$/ do |body, destination|
  @receipts_received ||= {}
  @connection.send(destination, body) do |r|
    @receipts_received[r[:'receipt-id']] = r
  end
end

Then /^the client should have received a receipt for the last "([^"]*)"$/ do |command|
  fr = @sent_frames.select { |f| f.command == command }.last
  (@receipts_received && @receipts_received[fr[:'receipt']]).should_not be_nil
end

When /^the client subscribes to "([^"]*)" with a receipt$/ do |destination|
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.subscribe(destination)
end

When /^the client unsubscribes from "([^"]*)" with a receipt$/ do |subscription|
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.unsubscribe(subscription)
end

When /^the client begins transaction "([^"]*)" with a receipt$/ do |tx|
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.begin(tx)
end

When /^the client aborts transaction "([^"]*)" with a receipt$/ do |tx|
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.abort(tx)
end

When /^the client commits transaction "([^"]*)" with a receipt$/ do |tx|
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.commit(tx)
end

When /^the client acks message "([^"]*)" from "([^"]*)" with a receipt$/ do |m_id, sub_id|
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.ack(m_id, sub_id)
end

When /^the client nacks message "([^"]*)" from "([^"]*)" with a receipt$/ do |m_id, sub_id|
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.nack(m_id, sub_id)
end

When /^the client disconnects with a receipt$/ do
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.disconnect
end

When /^the client connects with a receipt$/ do
  @receipts_received ||= {}
  @connection.with_receipt do |r|
    @receipts_received[r[:'receipt-id']] = r
  end.transmit(Stomper::Frame.new('CONNECT'))
end

Then /^the client should not have added a receipt header to the last "([^"]*)"$/ do |command|
  fr = @sent_frames.select { |f| f.command == command }.last
  fr[:receipt].should be_nil
end
