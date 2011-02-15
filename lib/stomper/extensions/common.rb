# -*- encoding: utf-8 -*-

# Provides the common interface for a {Stomper::Connection} object.
module Stomper::Extensions::Common
  # Transmits a SEND frame to the broker with the specified destination, body
  # and headers.  If a block is given, a +receipt+ header will be included in the frame
  # and the block will be invoked when the corresponding RECEIPT frame
  # is received from the broker. The naming of this method bothers me as it
  # overwrites a core Ruby method but doing so maintains the consistency of
  # this interface. If you want to pass a message ala +Object#send+, use the
  # +__send__+ method instead.
  # @note You will need to use +__send__+ if you want the behavior of {Object#send}
  # @param [String] dest the destination for the SEND frame to be delivered to
  # @param [String] body the body of the SEND frame
  # @param [{Symbol => String}] additional headers to include in the generated frame
  # @yield [receipt] invoked when the receipt for this SEND frame has been received
  # @yieldparam [Stomper::Frame] receipt the RECEIPT frame sent by the broker
  # @return [Stomper::Frame] the SEND frame sent to the broker
  def send(dest, body, headers={}, &block)
    transmit create_frame('SEND', headers, { :destination => dest }, body)
  end
  alias :put :send
  
  # Transmits a SUBSCRIBE frame to the broker with the specified destination
  # and headers.  If a block is given, it will be invoked every time a MESSAGE
  # frame is received from the broker for this subscription.
  # @param [String] dest the destination for the SEND frame to be delivered to
  # @param [{Symbol => String}] additional headers to include in the generated frame
  # @yield [message] invoked when a MESSAGE frame for this subscription is received
  # @yieldparam [Stomper::Frame] message the MESSAGE frame sent by the broker
  # @return [Stomper::Frame] the SUBSCRIBE frame sent to the broker
  def subscribe(dest, headers={}, &block)
    headers[:id] ||= ::Stomper::Support.next_serial
    transmit create_frame('SUBSCRIBE', headers, { :destination => dest })
  end
  
  # Transmits an UNSUBSCRIBE frame to the broker for the supplied subscription ID,
  # or SUBSCRIBE frame.
  # @param [Stomper::Frame, String] frame_or_id the subscription ID or SUBSCRIBE
  #   frame to unsubscribe from
  # @return [Stomper::Frame] the UNSUBSCRIBE frame sent to the broker
  # @raise [ArgumentError] if subscription ID cannot be determined.
  def unsubscribe(frame_or_id, headers={})
    sub_id = frame_or_id.is_a?(::Stomper::Frame) ? frame_or_id[:id] : frame_or_id
    raise ArgumentError, 'subscription ID could not be determined' if sub_id.nil? || sub_id.empty?
    transmit create_frame('UNSUBSCRIBE', headers, { :id => sub_id })
  end
  
  # Transmits a BEGIN frame to the broker to start a transaction named by +tx_id+.
  # When directly handling transaction management in this fashion, it is up to
  # you to ensure the uniqueness of transaction ids, that frames within this
  # transaction have their +transaction+ header set, and that transactions are
  # appropriately committed or aborted.
  # @see Stomper::Extensions::Scoping#with_transaction
  # @see #abort
  # @see #commit
  # @param [String] tx_id ID of the transaction to begin
  # @param [{Symbol => String}] additional headers to include in the generated frame
  # @return [Stomper::Frame] the BEGIN frame sent to the broker
  def begin(tx_id, headers={})
    transmit create_frame('BEGIN', headers, {:transaction => tx_id})
  end
  
  # Transmits an ABORT frame to the broker to rollback a transaction named by +tx_id+.
  # When directly handling transaction management in this fashion, it is up to
  # you to ensure the uniqueness of transaction ids, that frames within this
  # transaction have their +transaction+ header set, and that transactions are
  # appropriately committed or aborted.
  # @see Stomper::Extensions::Scoping#with_transaction
  # @see #begin
  # @see #commit
  # @param [String] tx_id ID of the transaction to abort
  # @param [{Symbol => String}] additional headers to include in the generated frame
  # @return [Stomper::Frame] the ABORT frame sent to the broker
  def abort(tx_id, headers={})
    transmit create_frame('ABORT', headers, {:transaction => tx_id})
  end
  
  # Transmits a COMMIT frame to the broker to complete a transaction named by +tx_id+.
  # When directly handling transaction management in this fashion, it is up to
  # you to ensure the uniqueness of transaction ids, that frames within this
  # transaction have their +transaction+ header set, and that transactions are
  # appropriately committed or aborted.
  # @see Stomper::Extensions::Scoping#with_transaction
  # @see #begin
  # @see #abort
  # @param [String] tx_id ID of the transaction to complete
  # @param [{Symbol => String}] additional headers to include in the generated frame
  # @return [Stomper::Frame] the COMMIT frame sent to the broker
  def commit(tx_id, headers={})
    transmit create_frame('COMMIT', headers, {:transaction => tx_id})
  end
  
  def create_frame(command, u_head, m_head, body=nil)
    ::Stomper::Frame.new(command,
      ::Stomper::Support.keys_to_sym(u_head).merge(m_head), body)
  end
  private :create_frame
end
