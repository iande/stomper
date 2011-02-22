# -*- encoding: utf-8 -*-

# This class serializes Stomp frames to IO streams. Submodule mixins within
# this class are used to adjust the serialization behavior depending upon
# the Stomp Protocol version being used.
class Stomper::FrameSerializer
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
  # the character read is a {FRAME_TERMINATOR frame terminator}.
  # @return [String,nil] the byte read from the stream.
  def get_body_byte
    c = @io.getc.chr
    c == FRAME_TERMINATOR ? nil : c
  end
  
  # @note If a content type header is specified but no charset parameter is
  #   inluded, a charset of UTF-8 is assumed. You have been warned.
  def determine_content_type(frame)
    ct = frame[:'content-type']
    if ct =~ /^text\//i && !(ct =~ /\;\s*charset=\"?[a-zA-Z0-9!\#$&.+\-^_]+\"?/i)
      "#{ct};charset=UTF-8"
    else
      ct
    end
  end
  
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
