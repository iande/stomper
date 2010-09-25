module Stomper
  module Frames
    # Encapsulates a "SUBSCRIBE" frame from the Stomp Protocol.
    class Subscribe < Stomper::Frames::ClientFrame
      def initialize(destination, headers={})
        super({ :ack => 'auto' }.merge(headers).merge({ :destination => destination }))
      end

      # Returns the ack mode of this subscription. (defaults to 'auto')
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers[:ack]
      def ack
        @headers[:ack]
      end

      # Returns the destination to which we are subscribing.
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers[:destination]
      def destination
        @headers[:destination]
      end

      # Returns the id of this subscription, if it has been set.
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers[:id]
      def id
        @headers[:id]
      end

      # Returns the selector header of this subscription, if it has been set.
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers[:selector]
      def selector
        @headers[:selector]
      end
    end
  end
end
