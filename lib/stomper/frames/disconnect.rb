module Stomper
  module Frames
    # Encapsulates a "DISCONNECT" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Disconnect < Stomper::Frames::ClientFrame
      def initialize(headers={})
        super(headers)
      end
    end
  end
end
