module Stomper
  module Frames
    class Receipt < Stomper::Frames::ServerFrame
      frame_factory :receipt
      attr_reader :for

      def initialize(headers, body)
        super('RECEIPT', headers, body)
        @for = headers['receipt-id']
      end
    end
  end
end
