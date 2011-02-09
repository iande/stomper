# -*- encoding: utf-8 -*-

# This module serves as a mixin for +IO+ objects to simplify frame reading
# and writing.  While this module was built around Ruby's +BasicSocket+,
# it can be mixed into any class whose instances conform to the following
# interface:
#
# - read(Fixnum) => String
# - gets => String
# - getc => String
# - write(String)
#
# This includes most of Ruby's standard IO objects.
module Stomper::FrameIO
  # Frame termination character as specified by the Stomp Protocol
  FRAME_TERMINATOR = "\000".chr
  
  # Mapping of escape sequences to their appropriate characters. This
  # is used when unescaping headers being read from the stream.
  ESCAPE_SEQUENCES = {
    'c' => ':',
    '\\' => "\\",
    'n' => "\n"
  }
  
  # Mapping of characters to their appropriate escape sequences. This
  # is used when escaping headers for frames being written to the stream.
  CHARACTER_ESCAPES = {
    ':' => "\\c",
    "\n" => "\\n",
    "\\" => "\\\\"
  }
  
  # Serializes a {Stomper::Frame} and writes it to the underlying IO stream
  #
  # @param [Stomper::Frame] frame the frame to serialize to the IO stream
  # @return [FrameIO] self
  def write_frame(frame)
    if frame.command
      write [frame.command, "\n", serialize_headers(frame),
        "\n", frame.body, FRAME_TERMINATOR].compact.join
    else
      write "\n"
    end
    self
  end
  
  # Deserializes and returns a {Stomper::Frame} read from the underlying IO
  # stream.  If the IO stream produces data that violates the Stomp protocol
  # specification, an instance of {Stomper::Errors::FatalProtocolError}, or
  # one of its subclasses, will be raised.
  #
  # @return [Stomper::Frame]
  # @raise [Stomper::Errors::FatalProtocolError]
  def read_frame
    command = gets.chomp
    frame = Stomper::Frame.new
    unless command.empty?
      frame.command = command

      while parse_header_line(frame)
      end
      body = nil
      if frame['content-length'] && (len = frame['content-length'].to_i) > 0
        body = read len
        raise ::Stomper::Errors::MalformedFrameError, "frame was not properly terminated" if get_body_byte
      else
        while (c = get_body_byte)
          body ||= ""
          body << c
        end
      end
      frame.body = body && encode_body(body, frame['content-type'])
    end
    frame
  end
  
  private
  def encode_body(body, ct_header)
    if ct_header
      charset = $1 if ct_header =~ /\;\s*charset=\"?([\w\-]+)\"?/i
      charset ||= (ct_header =~ /^text\// && 'UTF-8')
      if charset
        body.force_encoding(charset)
      end
    else
      body.force_encoding('US-ASCII')
    end
    body
  end
  
  def escape_header(hdr)
    hdr.each_char.inject('') do |esc, ch|
      esc << (CHARACTER_ESCAPES[ch] || ch)
    end
  end
  
  def serialize_headers(frame)
    serialized = frame.headers.inject('') do |head_str, (k, v)|
      k = escape_header(k)
      next if ['content-type', 'content-length'].include?(k) || k.empty?
      v = escape_header(v)
      head_str << "#{k}:#{v}\n"
      head_str
    end
    if frame.content_type_and_charset
      serialized << "content-type:#{frame.content_type_and_charset}\n"
    end
    if frame.body
      serialized << "content-length:#{frame.body.bytesize}\n"
    end
    serialized
  end
  
  def get_body_byte
    c = getc
    c == FRAME_TERMINATOR ? nil : c
  end
  
  def parse_header_line(frame)
    header_line = gets_encoded.chomp
    if header_line.length > 0
      cur_state = :read_string
      cur_idx = 0
      header_name, header_value = header_line.each_char.inject(['', '']) do |nvp, ch|
        case cur_state
        when :read_string
          if ch == ':'
            cur_idx = 1
          elsif ch == '\\'
            cur_state = :escape_sequence
          else
            nvp[cur_idx] << ch
          end
        when :escape_sequence
          cur_state = :read_string
          if ESCAPE_SEQUENCES[ch]
            nvp[cur_idx] << ESCAPE_SEQUENCES[ch]
          else
            raise ::Stomper::Errors::InvalidHeaderEscapeSequenceError, "invalid header escape sequence encountered '\\#{ch}'"
          end
        end
        nvp
      end
      raise ::Stomper::Errors::MalformedHeaderError, "unterminated header: '#{header_name}'" if cur_idx < 1
      frame.headers.append(header_name, header_value)
      true
    else
      nil
    end
  end
  
  def gets_encoded
    line = gets
    line.force_encoding("UTF-8")
    line
  end
end
