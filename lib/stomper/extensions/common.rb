# -*- encoding: utf-8 -*-

# Provides the common interface for a {Stomper::Connection} object.
module Stomper::Extensions::Common
  # Extends an object with any additional modules that are appropriate
  # for the Stomp protocol being used.
  def self.extend_by_protocol_version(instance, version)
    if EXTEND_BY_VERSION[version]
      EXTEND_BY_VERSION[version].each do |mod|
        instance.extend mod
      end
    end
  end
  
  
  # Transmits a SEND frame to the broker with the specified destination, body
  # and headers.  If a block is given, a +receipt+ header will be included in the frame
  # and the block will be invoked when the corresponding RECEIPT frame
  # is received from the broker. The naming of this method bothers me as it
  # overwrites a core Ruby method but doing so maintains the consistency of
  # this interface. If you want to pass a message ala +Object#send+, use the
  # +__send__+ method instead.
  # @note You will need to use +__send__+ if you want the behavior of +Object#send+
  # @param [String] dest the destination for the SEND frame to be delivered to
  # @param [String] body the body of the SEND frame
  # @param [{Symbol => String}] additional headers to include in the generated frame
  # @yield [receipt] invoked when the receipt for this SEND frame has been received
  # @yieldparam [Stomper::Frame] receipt the RECEIPT frame sent by the broker
  # @return [Stomper::Frame] the SEND frame sent to the broker
  def send(dest, body, headers={}, &block)
    scoped_to = block ? with_receipt(&block) : self
    scoped_to.transmit create_frame('SEND', headers, { :destination => dest }, body)
  end
  alias :puts :send
  
  # Transmits a SUBSCRIBE frame to the broker with the specified destination
  # and headers.  If a block is given, it will be invoked every time a MESSAGE
  # frame is received from the broker for this subscription.
  # @param [String] dest the destination for the SEND frame to be delivered to
  # @param [{Symbol => String}] additional headers to include in the generated frame
  # @yield [message] invoked when a MESSAGE frame for this subscription is received
  # @yieldparam [Stomper::Frame] message the MESSAGE frame sent by the broker
  # @return [Stomper::Frame] the SUBSCRIBE frame sent to the broker
  def subscribe(dest, headers={}, &block)
    ::Stomper::Support.keys_to_sym!(headers)
    if headers[:id].nil? || headers[:id].empty?
      headers[:id] = ::Stomper::Support.next_serial
    end
    subscribe = create_frame('SUBSCRIBE', headers, { :destination => dest })
    subscription_manager.add(subscribe, block) if block
    transmit subscribe
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
    subscription_manager.remove(sub_id).map do |id|
      transmit create_frame('UNSUBSCRIBE', headers, { :id => id })
    end.last
  end
  
  # Resubscribes to subscriptions that were not unsubscribed from before the
  # connection was last disconnected.
  def resubscribe
    subscription_manager.inactive_subscriptions.each do |sub|
      headers = sub.frame.headers.to_h
      headers.delete(:id)
      headers.delete(:destination)
      if subscribe(sub.destination, headers, &sub.callback)
        subscription_manager.remove_inactive(sub.id)
      end
    end
    self
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
  
  # Disconnects from the broker. This is polite disconnect, in that it first
  # transmits a DISCONNECT frame before closing the underlying socket. If the
  # broker and client are using the Stomp 1.1 protocol, a receipt can be requested
  # for the DISCONNECT frame, and the connection will remain active until
  # the receipt is received or the broker closes the connection on its end.
  # @param [{Symbol => String}] an optional set of headers to include in the
  #   DISCONNECT frame (these can include event handlers, such as :on_receipt)
  def disconnect(headers={})
    transmit create_frame('DISCONNECT', headers, {})
  end
  
  # Transmits an ACK frame to the broker to acknowledge that a corresponding
  # MESSAGE frame has been processed by the client.
  # @note If the negotiated Stomp protocol version is 1.1, this method will be
  #   overridden by {Stomper::Extensions::Common::V1_1#ack}
  # @overload ack(message, headers={})
  #   @param [Stomper::Frame] message the MESSAGE frame to acknowledge
  #   @param [{Object => String}] headers optional headers to include with the ACK frame
  # @overload ack(message_id, headers={})
  #   @param [String] message_id the ID of a MESSAGE frame to acknowledge
  #   @param [{Object => String}] headers optional headers to include with the ACK frame
  # @return [Stomper::Frame] the ACK frame sent to the broker
  # @example Gonna need some examples for this one...
  def ack(*args)
    headers = args.last.is_a?(Hash) ? args.pop : {}
    m_id = args.shift
    if m_id.is_a?(::Stomper::Frame)
      m_id = m_id[:'message-id']
    end
    m_headers = [ [:'message-id', m_id] ].inject({}) do |mh, (k,v)|
      mh[k] = v unless v.nil? || v.empty?
      mh
    end
    an_frame = create_frame('ACK', headers, m_headers)
    raise ::ArgumentError, 'message ID could not be determined' if an_frame[:'message-id'].nil? || an_frame[:'message-id'].empty?
    transmit an_frame
  end

  # Always raises an error because the NACK frame is only available to connections
  # using version 1.1 of the Stomp protocol.
  # @note If the negotiated Stomp protocol version is 1.1, this method will be
  #   overridden by {Stomper::Extensions::Common::V1_1#nack}
  # @see Stomper::Extensions::Protocol_1_1#nack
  # @raise [Stomper::Errors::UnsupportedCommandError]
  def nack(*args)
    raise ::Stomper::Errors::UnsupportedCommandError, 'NACK'
  end
  
  def create_frame(command, u_head, m_head, body=nil)
    ::Stomper::Frame.new(command,
      ::Stomper::Support.keys_to_sym(u_head).merge(m_head), body)
  end
  private :create_frame
  
  # Stomp Protocol 1.1 extensions to the common interface.
  module V1_1
    # Acknowledge that a MESSAGE frame has been received and successfully 
    # processed. The Stomp 1.1 protocol now requires that both ID of the
    # message and the ID of the subscription the message arrived on must be
    # specified in the ACK frame's headers.
    # @overload ack(message, headers={})
    #   Transmit an ACK frame fro the MESSAGE frame. The appropriate
    #   subscription ID will be determined from the MESSAGE frame's
    #   +subscription+ header value.
    #   @param [Stomper::Frame] message the MESSAGE frame to acknowledge
    #   @param [{Object => String}] headers optional headers to include with the ACK frame
    # @overload ack(message, subscription_id, headers={})
    #   Transmit an ACK frame for the MESSAGE frame, but use the supplied
    #   subscription ID instead of trying to determine it from the MESSAGE
    #   frame's headers. You should use this method of the broker you are
    #   connected to does not include a +subscribe+ header on MESSAGE frames.
    #   @param [Stomper::Frame] message the MESSAGE frame to acknowledge
    #   @param [String] subscription_id the ID of the subscription MESSAGE was delivered on.
    #   @param [{Object => String}] headers optional headers to include with the ACK frame
    # @overload ack(message_id, subscription_id, headers={})
    #   Transmit an ACK frame for the MESSAGE frame with an ID of +message_id+
    #   delivered on the subscription with an ID of +subscription_id+.
    #   @param [String] message_id the ID of the MESSAGE frame to acknowledge
    #   @param [String] subscription_id the ID of the subscription MESSAGE was delivered on.
    #   @param [{Object => String}] headers optional headers to include with the ACK frame
    # @return [Stomper::Frame] the ACK frame sent to the broker
    # @raise [ArgumentError] if the message or subscription IDs cannot be
    #   determined
    # @example Gonna need some examples for this one...
    def ack(message_or_id, *args)
      transmit create_ack_or_nack('ACK', message_or_id, args)
    end

    # Inform the broker that a MESSAGE frame was not processed. A NACK frame
    # is, in effect, the opposite of an ACK frame. The NACK command is a new
    # feature introduced in Stomp 1.1, hence why it is unavailable to Stomp
    # 1.0 connections.
    # @overload nack(message, headers={})
    #   Transmit a NACK frame fro the MESSAGE frame. The appropriate
    #   subscription ID will be determined from the MESSAGE frame's
    #   +subscription+ header value.
    #   @param [Stomper::Frame] message the MESSAGE frame to un-acknowledge
    #   @param [{Object => String}] headers optional headers to include with the NACK frame
    # @overload nack(message, subscription_id, headers={})
    #   Transmit a NACK frame for the MESSAGE frame, but use the supplied
    #   subscription ID instead of trying to determine it from the MESSAGE
    #   frame's headers. You should use this method of the broker you are
    #   connected to does not include a +subscribe+ header on MESSAGE frames.
    #   @param [Stomper::Frame] message the MESSAGE frame to un-acknowledge
    #   @param [String] subscription_id the ID of the subscription MESSAGE was delivered on.
    #   @param [{Object => String}] headers optional headers to include with the NACK frame
    # @overload nack(message_id, subscription_id, headers={})
    #   Transmit a NACK frame for the MESSAGE frame with an ID of +message_id+
    #   delivered on the subscription with an ID of +subscription_id+.
    #   @param [String] message_id the ID of the MESSAGE frame to un-acknowledge
    #   @param [String] subscription_id the ID of the subscription MESSAGE was delivered on.
    #   @param [{Object => String}] headers optional headers to include with the NACK frame
    # @return [Stomper::Frame] the NACK frame sent to the broker
    # @raise [ArgumentError] if the message or subscription IDs cannot be
    #   determined
    # @example Gonna need some examples for this one...
    def nack(message_or_id, *args)
      transmit create_ack_or_nack('NACK', message_or_id, args)
    end

    def create_ack_or_nack(command, m_id, args)
      headers = args.last.is_a?(Hash) ? args.pop : {}
      sub_id = args.shift
      if m_id.is_a?(::Stomper::Frame)
        sub_id = m_id[:subscription] if sub_id.nil? || sub_id.empty?
        m_id = m_id[:'message-id']
      end
      [[:message, m_id], [:subscription, sub_id]].each do |(k,v)|
        raise ::ArgumentError, "#{k} ID could not be determined" if v.nil? || v.empty?
      end
      create_frame(command, headers,
        {:'message-id' => m_id, :subscription => sub_id })
    end
    private :create_ack_or_nack
  end
  
  # A mapping between protocol versions and modules to include
  EXTEND_BY_VERSION = {
    '1.0' => [ ],
    '1.1' => [ ::Stomper::Extensions::Common::V1_1 ]
  }
end
