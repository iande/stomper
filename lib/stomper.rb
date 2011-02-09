# -*- encoding: utf-8 -*-

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

# Primary namespace of the stomper gem.
module Stomper
end

require 'stomper/version'
require 'stomper/support'
require 'stomper/errors'
require 'stomper/headers'
require 'stomper/frame_io'
require 'stomper/sockets'
require 'stomper/frame'
require 'stomper/uris'
require 'stomper/extensions'
require 'stomper/connection'
