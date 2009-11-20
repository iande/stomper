module Stomper
  module Frames
    class Begin < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super('BEGIN', headers)
        @headers['transaction'] = transaction_id.to_s
      end
    end
  end
end
