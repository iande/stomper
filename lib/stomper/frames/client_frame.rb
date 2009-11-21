module Stomper
  module Frames
    class ClientFrame
      attr_reader :headers, :body, :command

      def initialize(command, headers={})
        @command = command
        @headers = Headers.new(headers)
      end
      
      def to_stomp(skip_content_length=false)
        unless skip_content_length || @body.nil? || @body.bytesize == 0
          # use bytesize as it's what the broker will expect
          @headers["content-length"] = @body.bytesize
        end
        "#{@command}\n#{@headers.to_stomp}\n#{@body}\0"
      end
    end
  end
end
