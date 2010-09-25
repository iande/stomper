module Stomper
  module Frames
    # Encapsulates a "CONNECT" frame from the Stomp Protocol.
    class Connect < Stomper::Frames::ClientFrame
      def initialize(login='', passcode='', headers={})
        super(headers.merge({ :login => login, :passcode => passcode }))
      end
    end
  end
end
