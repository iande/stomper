module Stomper
  module Frames
    # Encapsulates a "CONNECT" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Connect < Stomper::Frames::ClientFrame
      def initialize(login='', passcode='', headers={})
        super(headers.merge({ :login => login, :passcode => passcode }))
      end
    end
  end
end
