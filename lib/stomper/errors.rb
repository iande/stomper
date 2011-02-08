# -*- encoding: utf-8 -*-

# Namespace for exceptions associated with this gem.
module Stomper::Errors
  # A common base class for errors raised by the Stomper gem
  # @abstract
  class StomperError < StandardError; end
  
  # Low level error raised when the broker transmits data that violates
  # the Stomp protocol specification.
  # @abstract
  class FatalProtocolError < StomperError; end
  
  # Raised when an invalid character is encountered in a header
  class InvalidHeaderCharacterError < FatalProtocolError; end
  
  # Raised when an invalid escape sequence is encountered in a header name or value
  class InvalidHeaderEscapeSequenceError < FatalProtocolError; end
  
  # Raised when a malformed header is encountered. For example, if a header
  # line does not contain ':'
  class MalformedHeaderError < FatalProtocolError; end
  
  # Raised when a malformed frame is encountered on the stream. For example,
  # if a frame is not properly terminated with the {Stomper::FrameIO::FRAME_TERMINATOR}
  # character.
  class MalformedFrameError < FatalProtocolError; end
  
  # An error that is raised as a result of a misconfiguration of the client
  # connection
  # @abstract
  class FatalConnectionError < StomperError; end
  
  # Raised when a connection has been configured with an unsupported protocol
  # version. This can be due to end user misconfiguration, or due to improper
  # protocol negotiation with the message broker.
  class UnsupportedProtocolVersionError < FatalConnectionError; end
  
  # Raised when an attempt to connect to the broker results in an unexpected
  # exchange.
  class ConnectFailedError < FatalConnectionError; end
  
  # Raised if the command issued is not supported by the protocol version
  # negotiated between the client and broker.
  class UnsupportedCommandError < StomperError; end
end
