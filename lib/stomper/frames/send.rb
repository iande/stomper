module Stomper
  module Frames
    # Encapsulates a "SEND" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Send < Stomper::Frames::ClientFrame
      def initialize(destination, body, headers={})
        super('SEND', headers, body)
        @headers[:destination] = destination
      end
    end
  end
end
