module Stomper
  module Frames
    class ClientFrame
      attr_reader :headers, :body, :command

      def initialize(command, headers={})
        @command = command
        @headers = headers
      end
      
      def to_stomp
        unless @body.nil? || @body.length == 0
          @headers["content-length"] = @body.length
          @headers["content-type"] = "text/plain; charset=UTF-8"
        end
        if @headers.size > 0
          str_head = @headers.map { |k,v| "#{k}:#{v}" }.join("\n") + "\n"
        end
        "#{@command}\n#{str_head}\n#{@body}\0"
      end
    end
  end
end
