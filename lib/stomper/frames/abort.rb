module Stomper
  module Frames
    # Encapsulates an "ABORT" frame from the Stomp Protocol.
    class Abort < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super(headers.merge(:transaction => transaction_id))
      end
    end
  end
end
