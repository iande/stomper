module Stomper
  module Frames
    class Send < Stomper::Frames::ClientFrame
      def initialize(destination, body, headers={})
        # When using an ActiveMQ broker with JMS based subscribers, the presence
        # of the 'content-length' header across the Stomp interface causes
        # ActiveMQ to create a BytesMessage, which can result in unexpected
        # messages for these receivers.  This provides a mechanism to skip
        # the auto-generation of the content-length header.
        # Covers the fork of the stomp library:
        # http://github.com/juretta/stomp/tree/activemq-jms-mapping
        @skip_content_length = headers.delete(:skip_content_length) { false }
        super('SEND', headers)
        @headers.destination = destination
        @body = body
      end

      def to_stomp
        super(@skip_content_length)
      end
    end
  end
end
