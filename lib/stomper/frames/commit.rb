module Stomper
  module Frames
    class Commit < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super('COMMIT', headers)
        @headers.transaction = transaction_id
      end
    end
  end
end
