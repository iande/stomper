# -*- encoding: utf-8 -*-

# Namespace for specific protocol version extensions.
# @note These all modules contained within this namespace require that the
#   includer/extender also includes/extends {Stomper::Extensions::Common}
module Stomper::Extensions::Protocols
  # Provides the Stomp 1.0 protocol specific interface
  # for a {Stomper::Connection} object.
  module V1_0
    # Transmits an ACK frame to the broker to acknowledge that a corresponding
    # MESSAGE frame has been processed by the client. The first argument must
    # be either the MESSAGE frame you wish to acknowledge or its ID. If
    # the final parameter to this method is a hash, it will used to apply
    # additional headers to the generated frame.
    # @param [Stomper::Frame, String] message_or_id the MESSAGE frame, or ID, to acknowledge
    # @return [Stomper::Frame] the ACK frame sent to the broker
    # @see Stomper::Extensions::Protocol_1_1#nack
    # @example Gonna need some examples for this one...
    def ack(*args)
      headers = args.last.is_a?(Hash) ? args.pop : {}
      m_id = args.shift
      if m_id.is_a?(::Stomper::Frame)
        m_id = m_id[:id]
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
    # @see Stomper::Extensions::Protocol_1_1#nack
    # @raise [Stomper::Errors::UnsupportedCommandError]
    def nack(*args)
      raise ::Stomper::Errors::UnsupportedCommandError, 'NACK'
    end
  end
  
  # Provides the Stomp 1.1 protocol specific interface
  # for a {Stomper::Connection} object.
  module V1_1
    # @todo Write a useful explanation.
    # @return [Stomper::Frame] the ACK frame sent to the broker
    # @raise [ArgumentError] if the message or subscription IDs cannot be
    #   determined
    # @example Gonna need some examples for this one...
    def ack(message_or_id, *args)
      transmit create_ack_or_nack('ACK', message_or_id, args)
    end

    # @todo Write a useful explanation.
    # @param [Stomper::Frame, String] message_or_id the MESSAGE frame, or ID, to un-acknowledge
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
        m_id = m_id[:id]
      end
      [[:message, m_id], [:subscription, sub_id]].each do |(k,v)|
        raise ::ArgumentError, "#{k} ID could not be determined" if v.nil? || v.empty?
      end
      create_frame(command, headers,
        {:'message-id' => m_id, :subscription => sub_id })
    end
    private :create_ack_or_nack
  end
  
  # A mapping between negotiated protocol versions and modules to include
  # to support said version.
  EXTEND_BY_VERSION = {
    '1.0' => [ ::Stomper::Extensions::Protocols::V1_0 ],
    '1.1' => [ ::Stomper::Extensions::Protocols::V1_1 ]
  }
end