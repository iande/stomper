module Stomper
  module Frames
    # Encapsulates a "CONNECTED" server side frame for the Stomp Protocol.
    class Connected < Stomper::Frames::ServerFrame

      # Builds a Connected frame instance with the supplied
      # +headers+ and +body+
      def initialize(headers, body)
        super(headers, body)
      end

      # A convenience method that returns the value of
      # the session header, if it is set.
      #
      # This value can also be accessed as:
      # frame.headers[:session]
      def session
        @headers[:session]
      end

      def perform
        # TODO: I want the frames, particularly the server frames, to know
        # 'what to do' when they are received.  For instance, when a CONNECTED
        # frame is received, the connection it is received on should be marked
        # as being "connected".  This way we can get rid of the various conditional
        # behavior based on Frame classes in connection and client.
      end
    end
  end
end
