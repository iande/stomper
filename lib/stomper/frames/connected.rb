module Stomper
  module Frames
    # Encapsulates a "CONNECTED" server side frame for the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Connected < Stomper::Frames::ServerFrame
      # This class is a factory for incoming 'CONNECTED' commands.
      factory_for :connected

      # Builds a Connected frame instance with the supplied
      # +headers+ and +body+
      def initialize(headers, body)
        super('CONNECTED', headers, body)
      end

      # A convenience method that returns the value of
      # the session header, if it is set.
      #
      # This value can also be accessed as:
      # frame.headers.session or frame.headers['session'] or frame.headers[:session]
      def session
        @headers.session
      end
    end
  end
end
