# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'stomper'

$stdout.puts "Starting demo"
$stdout.puts "----------------------------"

client = Stomper::Connection.new("stomp://localhost")
client.start

$stdout.puts "Connected to broker using protocol #{client.version}"

client.subscribe("/queue/stomper/test") do |message|
  $stdout.puts "Received: #{message.body}"
  if message.body == 'finished'
    client.stop
  end
end

client.send("/queue/stomper/test", "hello world")
client.send("/queue/stomper/test", "this is a simple demo of stomper")
client.send("/queue/stomper/test", "finished")

Thread.pass while client.running?
$stdout.puts "----------------------------"
$stdout.puts "End of demo"

# Example output:
#
#
# Starting demo
# ----------------------------
# Connected to broker using protocol 1.0
# Received: hello world
# Received: this is a simple demo of stomper
# Received: finished
# ----------------------------
# End of demo
