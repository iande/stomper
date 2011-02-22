# -*- encoding: utf-8 -*-

# Implementation of {Stomper::FrameSerializer} methods for Ruby 1.9
module Stomper::Support::Ruby1_9::FrameSerializer
  # Return the body with the specified encoding applied. An encoding
  # is specified in the 'content-type' header of a frame by the +charset+
  # parameter. If no encoding was explicitly specified, a UTF-8 encoding
  # is used when the frame's content type begins with +text/+, otherwise
  # an encoding of US-ASCII is used.
  # @param [String] body body of message to encode
  # @param [String] ct content-type header of frame
  # @return [String] body with the appropriate encoding applied
  def encode_body(body, ct_header)
    body.tap do |b|
      charset = ct_header ?
        (ct_header =~ /\;\s*charset=\"?([\w\-]+)\"?/i) ? $1 :
          (ct_header =~ /^text\//) ? 'UTF-8' : 'ASCII-8BIT' :
        'ASCII-8BIT'
      b.force_encoding(charset)
    end
  end
  
  # Reads a single byte from the body portion of a frame. Returns +nil+ if
  # the character read is a {::Stomper::FrameSerializer::FRAME_TERMINATOR frame terminator}.
  # @return [String,nil] the byte read from the stream.
  def get_body_byte
    #raise "Implementation varies by Ruby version"
    c = @io.getc
    c == ::Stomper::FrameSerializer::FRAME_TERMINATOR ? nil : c
  end
  
  # Determines the content-type of a frame being sent to a broker. This
  # version of the method is used by Ruby 1.9, and will use the encoding
  # of the frame's body to help determine the appropriate charset. If the
  # body's encoding is binary, no charset parameter will be included (even
  # if one was manually set.) Otherwise, if the content-type is ommitted,
  # a value of 'text/plain' is assumed and the encoding of the body is
  # used as the charset parameter.
  # @return [String] content-type and possibly charset of frame's body
  def determine_content_type(frame)
    ct = frame[:'content-type']
    ct &&= ct.gsub(/\;\s*charset=\"?[a-zA-Z0-9!\#$&.+\-^_]+\"?/i, '')
    enc = frame.body.encoding.name
    text = (enc != 'ASCII-8BIT') || ct =~ /^text\//
    ct = 'text/plain' if ct.nil? && text
    ct && text ? "#{ct};charset=#{enc}" : ct
  end
  
  # Determines the content-length of a frame being sent to a broker. For
  # Ruby 1.9, this is the +bytesize+ of the frame's body.
  # @return [Fixnum] byte-length of frame's body
  def determine_content_length(frame)
    frame.body.bytesize
  end
  
  # Reads a line of text from the underlying IO. As per the Stomp 1.1
  # specification, all header strings are encoded with UTF-8.
  # @return [String] line of text read from IO, or '' if no text was read.
  def get_header_line
    (@io.gets || '').tap { |line| line.force_encoding('UTF-8') }
  end
end

::Stomper::FrameSerializer.__send__(:include, ::Stomper::Support::Ruby1_9::FrameSerializer)
