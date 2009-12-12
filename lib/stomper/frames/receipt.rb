module Stomper
  module Frames
    # Encapsulates a "RECEIPT" server side frame for the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Receipt < Stomper::Frames::ServerFrame
      # This class is a factory for all RECEIPT commands received.
      factory_for :receipt

      # Creates a new Receipt frame with the supplied +headers+ and +body+
      def initialize(headers, body)
        super('RECEIPT', headers, body)
      end

      # Returns the 'receipt-id' header of the frame, which
      # will correspond to the 'receipt' header of the message
      # that caused this receipt to be sent by the stomp broker.
      def for
        @headers[:'receipt-id']
      end
    end
  end
end
