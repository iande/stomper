module Stomper
  module Frames
    class Receipt < Stomper::Frames::ServerFrame
      factory_for :receipt

      def initialize(headers, body)
        super('RECEIPT', headers, body)
      end

      def for
        @headers[:'receipt-id']
      end
    end
  end
end
