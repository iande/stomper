module Stomper
  module Frames
    class Abort < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super('ABORT', headers)
        @headers['transaction'] = transaction_id.to_s
      end
    end
  end
end
