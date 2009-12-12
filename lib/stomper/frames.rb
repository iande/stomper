require 'stomper/frames/headers'
require 'stomper/frames/client_frame'
require 'stomper/frames/server_frame'
require 'stomper/frames/abort'
require 'stomper/frames/ack'
require 'stomper/frames/begin'
require 'stomper/frames/commit'
require 'stomper/frames/connect'
require 'stomper/frames/connected'
require 'stomper/frames/disconnect'
require 'stomper/frames/error'
require 'stomper/frames/message'
require 'stomper/frames/receipt'
require 'stomper/frames/send'
require 'stomper/frames/subscribe'
require 'stomper/frames/unsubscribe'

module Stomper
  # This module holds all known encapsulations of
  # frames that are part of the
  # {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
  module Frames
  end
end
