module Stomper
  module Frames
    # Encapsulates a "BEGIN" frame from the Stomp Protocol.
    class Begin < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super(headers.merge(:transaction => transaction_id))
        @headers[:transaction] = transaction_id
      end
    end
  end
end
