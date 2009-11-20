module Stomper
  module Frames
    class Message < Stomper::Frames::ServerFrame
      frame_factory :message

      def initialize(headers, body)
        super('MESSAGE', headers, body)
      end

      # Convenience attributes
      def id
        @headers['message-id']
      end

      def destination
        @headers['destination']
      end

      def subscription
        @headers['subscription']
      end
    end
  end
end
