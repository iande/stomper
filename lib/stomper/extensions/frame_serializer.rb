# -*- encoding: utf-8 -*-

# This class serializes Stomp frames to IO streams. Submodule mixins within
# this class are used to adjust the serialization behavior depending upon
# the Stomp Protocol version being used.
class Stomper::Extensions::FrameSerializer
  FRAME_TERMINATOR = "\000".chr
  
  # Creates a new frame serializer that will read {Stomper::Frame frames} from
  # and write {Stomper::Frames frames} to the supplied IO object (typically
  # a TCP or SSL socket.)
  # @param [IO] io IO stream to read from and write to
  def initialize(io)
    @io = io
    # We will use V1_0 by default, until the connection has been established
    # and the protocol version has been negotiated.
    extend V1_0
  end
  
  # Extends the serializer based on the version of the protocol being used.
  # @param [String] version protocol version being used
  # @return [self]
  def extend_for_protocol(version)
    EXTEND_BY_VERSION[version].each { |m| extend m } if EXTEND_BY_VERSION[version]
    self
  end
  
  def write_frame(frame)
    if frame.command
      @io.write [frame.command, "\n", serialize_headers(frame),
        "\n", frame.body, FRAME_TERMINATOR].compact.join
    else
      @io.write "\n"
    end
    frame
  end
  
  # Deserializes and returns a {Stomper::Frame} read from the underlying IO
  # stream.  If the IO stream produces data that violates the Stomp protocol
  # specification, an instance of {Stomper::Errors::FatalProtocolError}, or
  # one of its subclasses, will be raised.
  #
  # @return [Stomper::Frame]
  # @raise [Stomper::Errors::MalformedFrameError] if the frame is not properly terminated
  # @raise [Stomper::Errors::MalformedHeaderError] if a header is malformed (eg: contains no ':' separator)
  def read_frame
    command = @io.gets.chomp
    frame = Stomper::Frame.new
    unless command.empty?
      frame.command = command
      
      while parse_header_line(frame); end
      
      body = nil
      if frame[:'content-length'] && (len = frame[:'content-length'].to_i) > 0
        body = @io.read len
        raise ::Stomper::Errors::MalformedFrameError, "frame was not properly terminated" if get_body_byte
      else
        while (c = get_body_byte)
          body ||= ""
          body << c
        end
      end
      frame.body = body && encode_body(body, frame[:'content-type'])
    end
    frame
  end
  
  def get_body_byte
    #raise "Implementation varies by Ruby version"
    c = @io.getc
    c == FRAME_TERMINATOR ? nil : c
  end
  private :get_body_byte
  
  # A helper to bridge the gap between Ruby 1.8.7 and Ruby 1.9. For now,
  # just raise an error.
  def bytesize_of_string(str)
    #raise "Implementation varies by Ruby version"
    str.bytesize
  end
  private :bytesize_of_string
  
  module V1_0
    # Return the body as it was passed. Stomp 1.0 has no concept of body
    # encoding.
    # @param [String] body body of message to encode
    # @param [String] ct content-type header of frame
    # @return [String]
    def encode_body(body, ct); body; end
    private :encode_body
    
    # Reads and parses a header line from the stream then adds it to the
    # headers of the supplied frame. Returns +false+ if no more headers are
    # available, +true+ otherwise.
    # @param [Stomper::Frame] frame frame being read from the stream
    # @return [true,false]
    def parse_header_line(frame)
      header_line = @io.gets.chomp
      if header_line.length > 0
        raise ::Stomper::Errors::MalformedHeaderError, "unterminated header: '#{header_line}'" unless header_line.include? ':'
        header_name, header_value = header_line.split(':', 2)
        frame.headers.append(header_name, header_value)
      else
        false
      end
    end
    private :parse_header_line
    
    # Converts the headers of the supplied frame into a single "\n" delimited
    # string that's suitable for writing to io.
    # @param [Stomper::Frame] frame the frame whose headers should be serialized
    # @return [String]
    def serialize_headers(frame)
      serialized = frame.headers.inject('') do |head_str, (k, v)|
        next if ['content-type', 'content-length'].include?(k) || k.empty?
        head_str << "#{k}:#{v}\n"
        head_str
      end
      if ct_charset = frame.content_type_and_charset
        serialized << "content-type:#{ct_charset}\n"
      end
      if frame.body
        serialized << "content-length:#{bytesize_of_string(frame.body)}\n"
      end
      serialized
    end
    private :serialize_headers
  end
  
  module V1_1
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
    
    def encode_body(body, ct_header)
      body.tap do |b|
        charset = ct_header ?
          (ct_header =~ /\;\s*charset=\"?([\w\-]+)\"?/i) ? $1 :
            (ct_header =~ /^text\//) ? 'UTF-8' : 'US-ASCII' :
          'US-ASCII'
        b.force_encoding(charset)
      end
    end
    private :encode_body

    def escape_header(hdr)
      hdr.each_char.inject('') do |esc, ch|
        esc << (CHARACTER_ESCAPES[ch] || ch)
      end
    end
    private :escape_header

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
    private :serialize_headers
    
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
    private :parse_header_line

    def gets_encoded
      @io.gets.tap do |line|
        line.force_encoding('UTF-8')
      end
    end
    private :gets_encoded
  end
  
  EXTEND_BY_VERSION = {
    '1.0' => [ ],
    '1.1' => [ ::Stomper::Extensions::FrameSerializer::V1_1 ]
  }
end
