module Stomper
  module Frames
    # Encapsulates an "UNSUBSCRIBE" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Unsubscribe < Stomper::Frames::ClientFrame
      def initialize(destination, headers={})
        super(headers.merge({ :destination => destination }))
      end

      # Returns the id of the subscription being unsubscribed from, if it
      # exists.
      #
      # This is a convenience method, and may also be accessed through
      # frame.headers[:id]
      def id
        @headers[:id]
      end
    end
  end
end
