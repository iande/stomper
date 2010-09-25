module Stomper
  module Frames
    # Encapsulates a "SEND" frame from the Stomp Protocol.
    class Send < Stomper::Frames::ClientFrame
      def initialize(destination, body, headers={})
        super(headers.merge({ :destination => destination }), body)
      end
    end
  end
end
