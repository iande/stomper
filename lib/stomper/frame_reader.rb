module Stomper
  # Deserializes Stomp Frames from an input stream.
  # Any object that responds appropriately to +getc+, +gets+
  # and +read+ can be used as the input stream.
  module FrameReader
    # Receives the next Stomp Frame from the socket stream
    def receive_frame
      command = read_command
      headers = read_headers
      body = read_body(headers[:'content-length'])
      Stomper::Frames::ServerFrame.build(command, headers, body)
    end

    private
    def read_command
      command = ''
      while(command.size == 0)
        command = gets(Stomper::Frames::LINE_DELIMITER).chomp!
      end
      command
    end

    def read_headers
      headers = {}
      loop do
        line = gets(Stomper::Frames::LINE_DELIMITER).chomp!
        break if line.size == 0
        if (delim = line.index(':'))
          headers[ line[0..(delim-1)].to_sym ] = line[(delim+1)..-1]
        end
      end
      headers
    end

    def read_body(body_len)
      body_len &&= body_len.strip.to_i
      if body_len
        read_fixed_body(body_len)
      else
        read_null_terminated_body
      end
    end

    def read_null_terminated_body
      body = ''
      while next_byte = get_body_byte
        body << next_byte.chr
      end
      body
    end

    def read_fixed_body(num_bytes)
      body = read(num_bytes)
      raise MalformedFrameError if get_body_byte
      body
    end

    def get_body_byte
      next_byte = get_ord
      (next_byte == Stomper::Frames::TERMINATOR) ? nil : next_byte
    end
    
    if String.method_defined?(:ord)
      def get_ord
        getc.ord
      end
    else
      def get_ord
        getc
      end
    end
  end
end
