module Stomper
  module Frames
    class ClientFrame
      attr_reader :headers, :body, :command

      def initialize(command, headers={}, body=nil)
        @command = command
        @generate_content_length = headers.delete(:generate_content_length)
        @headers = Headers.new(headers)
        @body = body
      end

      def generate_content_length=(bool)
        @generate_content_length=bool
      end

      def generate_content_length?
        @generate_content_length.nil? ? self.class.generate_content_length? : @generate_content_length
      end
      
      def to_stomp
        @headers["content-length"] = @body.bytesize if @body && !@body.empty? && generate_content_length?
        "#{@command}\n#{@headers.to_stomp}\n#{@body}\0"
      end

      class << self
        # When using an ActiveMQ broker with JMS based subscribers, the presence
        # of the 'content-length' header across the Stomp interface causes
        # ActiveMQ to create a BytesMessage, which can result in unexpected
        # messages for these receivers.  This provides a mechanism to skip
        # the auto-generation of the content-length header.
        # Covers the fork of the stomp library:
        # http://github.com/juretta/stomp/tree/activemq-jms-mapping
        def generate_content_length=(bool)
          @generate_content_length = bool
        end

        def generate_content_length?
          if @generate_content_length.nil?
            @generate_content_length = true
          end
          @generate_content_length
        end
      end
    end
  end
end
