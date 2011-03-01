Given /^a header scope with headers$/ do |table|
  headers = table_to_headers table
  @scope = @connection.with_headers(headers)
end

Given /^a transaction scope named "([^"]*)"$/ do |tx|
  @scope = @connection.with_transaction(:transaction => tx)
end

When /^the client begins the transaction scope$/ do
  @scope.begin
end


When /^the client aborts the transaction scope$/ do
  @scope.abort
end

When /^the client executes a successful transaction block named "([^"]*)"$/ do |tx|
  @connection.with_transaction(:transaction => tx) do |t|
    t.ack "message-id", "subscription-id"
    t.send "/queue/transaction/test", "message"
    t.nack "message-id-2", "subscription-id-2"
  end
end

When /^the client executes an unsuccessful transaction block named "([^"]*)"$/ do |tx|
  lambda do
    @connection.with_transaction(:transaction => tx) do |t|
      t.ack "message-id", "subscription-id"
      t.send "/queue/transaction/test", "message"
      t.nack "message-id-2", "subscription-id-2"
      raise "transaction will now fail"
    end
  end.should raise_error("transaction will now fail")
end
