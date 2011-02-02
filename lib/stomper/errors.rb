# -*- encoding: utf-8 -*-

# Namespace for exceptions associated with this gem.
module Stomper::Errors
  # A common base class for errors raised by the Stomper gem
  #
  # @abstract
  class StomperError < StandardError; end
  
  # Low level error raised when the broker transmits data that violates
  # the Stomp protocol specification.
  class FatalProtocolError < StomperError; end
  
  # Raised when an invalid character is encountered in a header
  class InvalidHeaderCharacter < FatalProtocolError; end
  
  # Raised when an invalid escape sequence is encountered in a header name or value
  class InvalidHeaderEscapeSequence < FatalProtocolError; end
  
  # Raised when a malformed header is encountered. For example, if a header
  # line does not contain ':'
  class MalformedHeader < FatalProtocolError; end
  
  # Raised when a malformed frame is encountered on the stream. For example,
  # if a frame is not properly terminated with the {Stomper::FrameIO::FRAME_TERMINATOR}
  # character.
  class MalformedFrame < FatalProtocolError; end
end
