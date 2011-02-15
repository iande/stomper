# -*- encoding: utf-8 -*-

# This class serializes Stomp frames to IO streams. Submodule mixins within
# this class are used to adjust the serialization behavior depending upon
# the Stomp Protocol version being used.
# @todo Make this work with Ruby 1.8.7
class Stomper::Extensions::FrameSerializer
  FRAME_TERMINATOR = "\000"
  
  # Creates a new frame serializer that will read {Stomper::Frame frames} from
  # and write {Stomper::Frame frames} to the supplied IO object (typically
  # a TCP or SSL socket.)
  # @param [IO] io IO stream to read from and write to
  def initialize(io)
    @io = io
    # All connections begin using Stomp 1.0 conventions
    extend_for_protocol '1.0'
  end
  
  # Extends the serializer based on the version of the protocol being used.
  # @param [String] version protocol version being used
  # @return [self]
  def extend_for_protocol(version)
    if EXTEND_BY_VERSION[version]
      EXTEND_BY_VERSION[version].each { |m| extend m } #unless self.is_a?(m) }
    end
    self
  end
  
  # Serializes and writes a {Stomper::Frame} to the underlying IO stream. This
  # includes setting the appropriate values for 'content-length' and
  # 'content-type' headers, if applicable.
  # @param [Stomper::Frame] frame
  # @return [Stomper::Frame] the frame that was passed to the method
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
  # stream. If the IO stream produces data that violates the Stomp protocol
  # specification, an instance of {Stomper::Errors::FatalProtocolError}, or
  # one of its subclasses, will be raised.
  # @return [Stomper::Frame]
  # @raise [Stomper::Errors::MalformedFrameError] if the frame is not properly terminated
  # @raise [Stomper::Errors::MalformedHeaderError] if a header is malformed (eg: contains no ':' separator)
  def read_frame
    command = @io.gets.chomp
    frame = Stomper::Frame.new
    unless command.empty?
      frame.command = command
      
      while (header_line = get_header_line.chomp).length > 0
        raise ::Stomper::Errors::MalformedHeaderError,
          "unterminated header: '#{header_line}'" unless header_line.include? ':'
        k, v = header_line.split(':', 2)
        frame.headers.append(unescape_header_name(k), unescape_header_value(v))
      end
      
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
  
  # Reads a single byte from the body portion of a frame. Returns +nil+ if
  # the character read is a {FRAME_TERMINATOR frame terminator}.
  # @return [String,nil] the byte read from the stream.
  def get_body_byte
    #raise "Implementation varies by Ruby version"
    c = @io.getc
    c == FRAME_TERMINATOR ? nil : c
  end
  
  # Returns the byte length of the given String. This is little more than
  # a helper method to keep the rest of the interface consistent between
  # Ruby 1.8.7 and Ruby 1.9.
  # @param [String] str
  # @return [Fixnum] byte length of +str+
  def bytesize_of_string(str)
    #raise "Implementation varies by Ruby version"
    str.bytesize
  end
  
  # Converts the headers of the supplied frame into a single "\n" delimited
  # string that's suitable for writing to io.
  # @param [Stomper::Frame] frame the frame whose headers should be serialized
  # @return [String]
  def serialize_headers(frame)
    serialized = frame.headers.inject('') do |head_str, (k, v)|
      k = escape_header_name(k)
      next head_str if k.empty? || ['content-type', 'content-length'].include?(k)
      head_str << "#{k}:#{escape_header_value(v)}\n"
    end
    if ct_charset = frame.content_type_and_charset
      serialized << "content-type:#{ct_charset}\n"
    end
    if frame.body
      serialized << "content-length:#{bytesize_of_string(frame.body)}\n"
    end
    serialized
  end
  
  module V1_0
    module Write
      def escape_header_name(str); str.gsub(/[\n:]/, ''); end
      def escape_header_value(str); str.gsub(/\n/, ''); end
    end
    
    module Read
      # Return the body as it was passed. Stomp 1.0 has no concept of body
      # encoding.
      # @param [String] body body of message to encode
      # @param [String] ct content-type header of frame
      # @return [String]
      def encode_body(body, ct); body; end
      def unescape_header_name(str); str; end
      alias :unescape_header_value :unescape_header_name
      def get_header_line; @io.gets || ''; end
    end
  end
  
  module V1_1
    module Write
      # Mapping of characters to their appropriate escape sequences. This
      # is used when escaping headers for frames being written to the stream.
      CHARACTER_ESCAPES = {
        ':' => "\\c",
        "\n" => "\\n",
        "\\" => "\\\\"
      }
      def escape_header_name(hdr)
        hdr.each_char.inject('') do |esc, ch|
          esc << (CHARACTER_ESCAPES[ch] || ch)
        end
      end
      alias :escape_header_value :escape_header_name
    end
    
    module Read
      # Mapping of escape sequences to their appropriate characters. This
      # is used when unescaping headers being read from the stream.
      ESCAPE_SEQUENCES = {
        'c' => ':',
        '\\' => "\\",
        'n' => "\n"
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
      
      def unescape_header_name(str)
        state = :read
        str.each_char.inject('') do |unesc, ch|
          case state
          when :read
            if ch == '\\'
              state = :unescape
            else
              unesc << ch
            end
          when :unescape
            state = :read
            if ESCAPE_SEQUENCES[ch]
              unesc << ESCAPE_SEQUENCES[ch]
            else
              raise ::Stomper::Errors::InvalidHeaderEscapeSequenceError,
                "invalid header escape sequence encountered '\\#{ch}'"
            end
          end
          unesc
        end.tap do
          raise ::Stomper::Errors::InvalidHeaderEscapeSequenceError,
            "incomplete escape sequence encountered in '#{str}'" if state != :read
        end
      end
      alias :unescape_header_value :unescape_header_name

      def get_header_line
        (@io.gets || '').tap { |line| line.force_encoding('UTF-8') }
      end
    end
  end
  
  EXTEND_BY_VERSION = {
    '1.0' => [
      ::Stomper::Extensions::FrameSerializer::V1_0::Write,
      ::Stomper::Extensions::FrameSerializer::V1_0::Read
    ],
    '1.1' => [
      ::Stomper::Extensions::FrameSerializer::V1_1::Write,
      ::Stomper::Extensions::FrameSerializer::V1_1::Read
    ]
  }
end
