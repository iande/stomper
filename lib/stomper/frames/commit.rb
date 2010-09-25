module Stomper
  module Frames
    # Encapsulates a "COMMIT" frame from the Stomp Protocol.
    class Commit < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super(headers.merge({ :transaction => transaction_id }))
      end
    end
  end
end
