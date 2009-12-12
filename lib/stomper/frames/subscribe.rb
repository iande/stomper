module Stomper
  module Frames
    # Encapsulates a "SUBSCRIBE" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Subscribe < Stomper::Frames::ClientFrame
      def initialize(destination, headers={})
        super('SUBSCRIBE', headers)
        @headers['destination'] = destination
        @headers['ack'] ||= 'auto'
      end

      # Returns the ack mode of this subscription. (defaults to 'auto')
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers.ack or frame.headers[:ack] or frame.headers['ack']
      def ack
        @headers['ack']
      end

      # Returns the destination to which we are subscribing.
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers.destination or frame.headers[:destination] or frame.headers['destination']
      def destination
        @headers['destination']
      end

      # Returns the id of this subscription, if it has been set.
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers.id or frame.headers[:id] or frame.headers['id']
      def id
        @headers['id']
      end

      # Returns the selector header of this subscription, if it has been set.
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers.selector or frame.headers[:selector] or frame.headers['selector']
      def selector
        @headers['selector']
      end
    end
  end
end
