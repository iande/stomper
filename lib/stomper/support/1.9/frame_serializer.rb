# -*- encoding: utf-8 -*-

# A Ruby 1.9 encoding support for frames
class Stomper::FrameSerializer
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
  # the character read is a {FRAME_TERMINATOR frame terminator}.
  # @return [String,nil] the byte read from the stream.
  def get_body_byte
    #raise "Implementation varies by Ruby version"
    c = @io.getc
    c == FRAME_TERMINATOR ? nil : c
  end
  
  def determine_content_type(frame)
    ct = frame[:'content-type']
    ct &&= ct.gsub(/\;\s*charset=\"?[a-zA-Z0-9!\#$&.+\-^_]+\"?/i, '')
    enc = frame.body.encoding.name
    text = (enc != 'ASCII-8BIT') || ct =~ /^text\//
    ct = 'text/plain' if ct.nil? && text
    ct && text ? "#{ct};charset=#{enc}" : ct
  end
  
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
