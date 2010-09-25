When /^the producer aborts "([^\"]*)" to "([^\"]*)"$/ do |body, destination|
  @producer.transaction do |t|
    t.send(destination, body)
    t.abort
  end
end

When /^the producer commits "([^\"]*)" to "([^\"]*)"$/ do |body, destination|
  @producer.transaction do |t|
    t.send(destination, body)
  end
  puts "Committed transaction!"
end

When /^the producer creates an exception while sending "([^\"]*)" to "([^\"]*)"$/ do |body, destination|
  @producer.transaction do |t|
    t.send(destination, body)
    raise "something exceptional"
  end
end