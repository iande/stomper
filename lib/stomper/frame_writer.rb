module Stomper

  # Serializes Stomp Frames to an output stream.
  # Any object that responds appropriately to +write+
  # can be used as the input stream.
  class FrameWriter
    def initialize(out_stream)
      @output_stream = out_stream
    end

    # Writes a Stomp Frame to the underlying output stream.
    def put_frame(frame)
      @output_stream.write("#{serialize_command(frame.command)}\n#{serialize_headers(frame.headers_with_content_length)}\n#{serialize_body(frame.body)}\0")
    end

    private
    def serialize_command(command)
      "#{command.upcase}"
    end

    def serialize_headers(headers)
      headers.sort { |a, b| a.first.to_s <=> b.first.to_s }.inject("") do |acc, (key, val)|
        acc << "#{key}:#{val}\n"
        acc
      end
    end

    def serialize_body(body)
      body
    end
  end
end
