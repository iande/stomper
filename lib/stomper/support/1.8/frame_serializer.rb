# -*- encoding: utf-8 -*-

# Implementation of {Stomper::FrameSerializer} methods for Ruby 1.8.7
module Stomper::Support::Ruby1_8::FrameSerializer
  # Return the body with the specified encoding applied. Ruby 1.8 does not
  # have a native awareness of string encodings. As such, this method does
  # not change the body in any way.
  # @param [String] body body of message to encode
  # @param [String] ct content-type header of frame
  # @return [String]
  def encode_body(body, ct_header)
    body
  end
  
  # Reads a single byte from the body portion of a frame. Returns +nil+ if
  # the character read is a {::Stomper::FrameSerializer::FRAME_TERMINATOR frame terminator}.
  # @return [String,nil] the byte read from the stream.
  def get_body_byte
    c = @io.getc.chr
    c == ::Stomper::FrameSerializer::FRAME_TERMINATOR ? nil : c
  end
  
  # Determines the content-type of a frame being sent to a broker. This
  # version of the method is used by Ruby 1.8.7, which lacks native string
  # encoding support. If the content-type matches 'text/*', and no charset
  # parameter is set, a charset of UTF-8 will be assumed. In all other
  # cases, the 'content-type' header is used directly.
  # @return [String] content-type and possibly charset of frame's body
  def determine_content_type(frame)
    ct = frame[:'content-type']
    if ct =~ /^text\//i && !(ct =~ /\;\s*charset=\"?[a-zA-Z0-9!\#$&.+\-^_]+\"?/i)
      "#{ct};charset=UTF-8"
    else
      ct
    end
  end
  
  # Determines the content-length of a frame being sent to a broker. For
  # Ruby 1.8.7, this is just the +size+ of the frame's body.
  # @return [Fixnum] byte-length of frame's body
  def determine_content_length(frame)
    frame.body.size
  end
  
  # Reads a line of text from the underlying IO. As per the Stomp 1.1
  # specification, all header strings are encoded with UTF-8.
  # @return [String] line of text read from IO, or '' if no text was read.
  def get_header_line
    @io.gets || ''
  end
end

::Stomper::FrameSerializer.__send__(:include, ::Stomper::Support::Ruby1_8::FrameSerializer)
