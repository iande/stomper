# -*- encoding: utf-8 -*-

# Namespace for specific protocol version extensions.
# @note These all modules contained within this namespace require that the
#   includer/extender also includes/extends {Stomper::Extensions::Common}
module Stomper::Extensions::Protocols
  # Extensions for {Stomper::Connection connections} that handle Stomp
  # protocol negotiation.
  module Negotiator
    def negotiate_protocol_version(connected, versions)
      version = connected[:version]
      version = '1.0' if version.nil? || version.empty?
      raise ::Stomper::Errors::UnsupportedProtocolVersionError,
        "broker requested '#{version}', client allows: #{versions.inspect}" unless versions.include?(version)
      version
    end
    private :negotiate_protocol_version
  end
  
  # Provides the Stomp 1.0 protocol specific interface
  # for a {Stomper::Connection} object.
  module V1_0
    # Transmits an ACK frame to the broker to acknowledge that a corresponding
    # MESSAGE frame has been processed by the client.
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