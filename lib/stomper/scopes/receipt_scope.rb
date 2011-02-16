# -*- encoding: utf-8 -*-

# Automatically generates "receipt" headers, if none are present and
# applies a supplied callback to every receipt received for frames generated
# through it. As instances of this class rely on event callbacks attached
# to the underlying {Stomper::Connection connection}, it is entirely possible
# for those events to be triggered on +Thread+ other than main. It is for
# this reason that synchronization is used to ensure the integrity of
# the internal list of receipt IDs that have not yet been processed through
# the callback.
class Stomper::Scopes::ReceiptScope < ::Stomper::Scopes::HeaderScope
  # A list of frames that support being receipted.
  # @return [Array<String>]
  FRAME_COMMANDS = %w(SEND SUBSCRIBE UNSUBSCRIBE
    BEGIN COMMIT ABORT ACK NACK DISCONNECT)
  
  # Create a new receipt scope. All receiptable frames transmitted through
  # this instance will use the same callback for handling the RECEIPT frame
  # sent by the broker.
  def initialize(parent, headers)
    super
    @receipt_ids = []
    @receipt_handler = nil
    @handler_installed = false
    @receipt_mutex = ::Mutex.new
  end
  
  # Takes a block as a callback to invoke when a receipt is received.
  def apply_to(callback)
    @receipt_handler = callback
  end
  
  # Transmits a frame. This method will add an auto-generated +receipt+ header
  # to the frame if one has not been set, and then set up a handler for the
  # +receipt+ value, invoking the callback set through {#apply_to} when
  # the corresponding RECEIPT frame is received from the broker.
  # @param [Stomper::Frame] frame
  def transmit(frame)
    if check_receipt_handler
      r_id = frame[:receipt]
      r_id = ::Stomper::Support.next_serial if r_id.nil? || r_id.empty?
      @receipt_mutex.synchronize do
        @receipt_ids << r_id
      end
      frame[:receipt] = r_id
    end
    super(frame)
  end
  
  private
  def check_receipt_handler
    if @receipt_handler && !@handler_installed
      @connection.on_receipt do |receipt|
        r_id = receipt[:'receipt-id']
        @receipt_mutex.synchronize do
          if @receipt_ids.include?(r_id)
            @receipt_handler.call(receipt)
            @receipt_ids.delete(r_id)
          end
        end
      end
      @handler_installed = true
    end
    @handler_installed
  end
end