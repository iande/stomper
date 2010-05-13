module Stomper
  # Serializes Stomp Frames to an output stream.
  # Any object that responds appropriately to +write+
  # can be used as the input stream.
  module FrameWriter
    # Writes a Stomp Frame to the underlying output stream.
    def transmit_frame(frame)
      headers = frame.headers
      write([ frame.command, Stomper::Frames::LINE_DELIMITER,
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
