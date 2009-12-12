module Stomper
  module Frames
    # Encapsulates a "COMMIT" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Commit < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super('COMMIT', headers)
        @headers.transaction = transaction_id
      end
    end
  end
end
