# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'stomper'

$stdout.puts "Starting demo"
$stdout.puts "----------------------------"

client = Stomper::Connection.open("stomp://localhost")

$stdout.puts "Connected to broker using protocol #{client.version}"

client.before_transmitting do |frame|
  $stdout.puts "Frame headers [#{frame.command}] before modification: #{frame.headers.to_a.inspect}"
  frame[:'x-alt-header'] = 'another value'
end

client.before_send do |frame|
  $stdout.puts "SEND headers before modification: #{frame.headers.to_a.inspect}"
  frame[:'x-misc-header'] = 'this is a test'
end

client.after_transmitting do |frame|
  $stdout.puts "Final frame headers [#{frame.command}]: #{frame.headers.to_a.inspect}"
end

client.before_disconnect do |frame|
  $stdout.puts "Disconnecting from broker"
end

client.on_connection_closed do |con|
  $stdout.puts "Connection has been closed"
end

client.send("/queue/stomper/test", "hello world")
client.disconnect

$stdout.puts "----------------------------"
$stdout.puts "End of demo"

# Example output:
#
#
# Starting demo
# ----------------------------
# Connected to broker using protocol 1.0
# Frame headers [SEND] before modification: [["destination", "/queue/stomper/test"]]
# SEND headers before modification: [["destination", "/queue/stomper/test"], ["x-alt-header", "another value"]]
# Final frame headers [SEND]: [["destination", "/queue/stomper/test"], ["x-alt-header", "another value"], ["x-misc-header", "this is a test"]]
# Frame headers [DISCONNECT] before modification: []
# Disconnecting from broker
# Final frame headers [DISCONNECT]: [["x-alt-header", "another value"]]
# Connection has been closed
# ----------------------------
# End of demo
