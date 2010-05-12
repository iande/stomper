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
      headers = frame.headers_with_content_length.sort { |key1, key2| key1.first.to_s <=> key2.first.to_s }
      @output_stream.write([
          frame.command, Stomper::Frames::LINE_DELIMITER,
          serialize_headers(headers), Stomper::Frames::LINE_DELIMITER,
          frame.body, Stomper::Frames::TERMINATOR.chr].join)
    end

    private
    def serialize_headers(headers)
      headers.inject("") do |acc, (key, val)|
        acc << "#{key}#{Stomper::Frames::HEADER_DELIMITER}#{val}#{Stomper::Frames::LINE_DELIMITER}"
        acc
      end
    end
  end
end
