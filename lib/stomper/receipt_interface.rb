module Stomper
  module ReceiptInterface
    def self.included(base)
      if base.method_defined?(:receive)
        base.instance_eval do
          alias_method :receive_without_receipt_dispatch, :receive
          alias_method :receive, :receive_with_receipt_dispatch
        end
      end
    end

    # Receives a frame and dispatches it to the known receipt handlers, if the
    # received frame is a RECEIPT frame.
    def receive_with_receipt_dispatch
      frame = receive_without_message_dispatch
      receipt_handlers.perform(frame) if frame.is_a?(Stomper::Frames::Receipt)
      frame
    end

    def receipt_handlers
      @receipt_handlers ||= ::Stomper::Frames::ReceiptHandlers.new
    end
  end
end
