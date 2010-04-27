module Stomper
  module Frames
    # Encapsulates a "BEGIN" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Begin < Stomper::Frames::ClientFrame
      def initialize(transaction_id, headers={})
        super('BEGIN', headers)
        @headers[:transaction] = transaction_id
      end
    end
  end
end
