module Stomper
  module Frames
    class Subscribe < Stomper::Frames::ClientFrame
      def initialize(destination, headers={})
        super('SUBSCRIBE', headers)
        @headers['destination'] = destination
        @headers['ack'] ||= 'auto'
      end

      def ack
        @headers['ack']
      end

      def destination
        @headers['destination']
      end

      def id
        @headers['id']
      end

      def selector
        @headers['selector']
      end
    end
  end
end
