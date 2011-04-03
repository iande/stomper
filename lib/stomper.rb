# -*- encoding: utf-8 -*-

$stderr.puts "The gem has been deprecated, please use onstomp instead."
$stderr.puts "\t\tgem install onstomp"
$stderr.puts "See https://github.com/meadvillerb/onstomp for more information."

# For extensions to URI.parse for Stomp schemes.
require 'uri'
# Primarily for CGI.parse
require 'cgi'
# Sockets are fairly important in all of this.
require 'socket'
# As is openssl
require 'openssl'
# For IO#ready?
require 'io/wait'
# The socket helpers use this to delegate to the real sockets
require 'delegate'
# Threading and Mutex support
require 'thread'
# Monitor support (prevent recursive dead locking)
require 'monitor'

# Primary namespace of the stomper gem.
module Stomper
end

require 'stomper/version'
require 'stomper/errors'
require 'stomper/headers'
require 'stomper/sockets'
require 'stomper/frame'
require 'stomper/uris'
require 'stomper/frame_serializer'
require 'stomper/subscription_manager'
require 'stomper/receipt_manager'
require 'stomper/receivers'
require 'stomper/extensions'
require 'stomper/scopes'
require 'stomper/support'
require 'stomper/connection'
