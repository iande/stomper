module Stomper
  module ReceiptInterface
    def self.included(base)
      if base.method_defined?(:receive)
        base.instance_eval do
          alias_method :receive_without_receipt_dispatch, :receive
          alias_method :receive, :receive_with_receipt_dispatch
        end
      end
      if base.method_defined?(:send)
        base.instance_eval do
          alias_method :send_without_receipt_handler, :send
          alias_method :send, :send_with_receipt_handler
        end
      end
    end

    # Receives a frame and dispatches it to the known receipt handlers, if the
    # received frame is a RECEIPT frame.
    def receive_with_receipt_dispatch
      frame = receive_without_receipt_dispatch
      receipt_handlers.perform(frame) if frame.is_a?(::Stomper::Frames::Receipt)
      frame
    end
    
    def send_with_receipt_handler(destination, body, headers={}, &block)
      if block_given?
        headers[:receipt] ||= "rcpt-#{Time.now.to_f}"
        receipt_handlers.add(headers[:receipt], block)
      end
      send_without_receipt_handler(destination, body, headers)
    end

    def receipt_handlers
      @receipt_handlers ||= ::Stomper::ReceiptHandlers.new
    end
  end
end
