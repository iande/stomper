module Stomper
  # This module holds all known encapsulations of
  # frames that are part of the Stomp Protocol specification.
  module Frames
    HEADER_DELIMITER = ':'
    TERMINATOR = 0
    LINE_DELIMITER = "\n"

    class IndirectFrame #:nodoc:
      attr_reader :headers, :body

      def initialize(headers={}, body=nil, command=nil)
        @command = command && command.to_s.upcase
        @headers = headers.dup
        @body = body
      end

      def command
        @command ||= self.class.name.split("::").last.upcase
      end
    end
  end
end

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
