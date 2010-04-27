module Stomper

  # Deserializes Stomp Frames from an input stream.
  # Any object that responds appropriately to +getc+, +gets+
  # and +read+ can be used as the input stream.
  class FrameReader
    def initialize(in_stream)
      @input_stream = in_stream
    end

    # Receives the next Stomp Frame from the underlying input stream
    def get_frame
      command = read_command
      headers = read_headers
      content_length = (headers.has_key?(:'content-length')) ? headers[:'content-length'].strip.to_i : nil
      body = read_body(content_length)
      Stomper::Frames::ServerFrame.build(command, headers, body).freeze
    end

    private
    def read_command
      command = ''
      while(command.size == 0)
        command = @input_stream.gets.chomp!
      end
      command
    end

    def read_headers
      headers = {}
      loop do
        line = @input_stream.gets.chomp!
        break if line.size == 0
        if (delim = line.index(':'))
          headers[ line[0..(delim-1)].to_sym ] = line[(delim+1)..-1]
        end
      end
      headers
    end

    def read_body(content_length = nil)
      body = ''
      if content_length
        body = @input_stream.read(content_length)
        raise MalformedFrameError if get_ord != 0
      else
        body = ''
        while (c = get_ord) != 0
          body << c.chr
        end
      end
      body
    end
    
    if String.method_defined?(:ord)
      def get_ord
        @input_stream.getc.ord
      end
    else
      def get_ord
        @input_stream.getc
      end
    end
  end
end
