module Stomper
  module Frames
    # Encapsulates a "DISCONNECT" frame from the Stomp Protocol.
    class Disconnect < Stomper::Frames::ClientFrame
      def initialize(headers={})
        super(headers)
      end
    end
  end
end
