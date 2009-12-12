module Stomper
  module Frames
    # Encapsulates an "ACK" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Abort < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super('ABORT', headers)
        @headers.transaction = transaction_id
      end
    end
  end
end
