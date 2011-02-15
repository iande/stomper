# -*- encoding: utf-8 -*-

# Namespace for specific protocol version extensions.
# @note These all modules contained within this namespace require that the
#   includer/extender also includes/extends {Stomper::Extensions::Common}
module Stomper::Extensions::Protocols
  # Extensions for {Stomper::Connection connections} that handle Stomp
  # protocol negotiation.
  module Negotiator
    def negotiate_protocol_version(connected)
      version = connected[:version]
      version = '1.0' if version.nil? || version.empty?
      version
    end
    private :negotiate_protocol_version
  end
  
  # Extensions for {Stomper::Connection connections} that handle Stomp
  # heart beating negotiation.
  module Heartbeats
    def negotiate_heartbeats(connected, client)
      c_x, c_y = client
      s_x, s_y = (connected[:'heart-beat'] || '0,0').split(',').map do |v|
        vi = v.to_i
        vi > 0 ? vi : 0
      end
      [ (c_x == 0 || s_y == 0 ? 0 : [c_x, s_y].max),
        (c_y == 0 || s_x == 0 ? 0 : [c_y, s_x].max) ]
    end
    private :negotiate_heartbeats
  end
  
  # Provides the Stomp 1.0 protocol specific interface
  # for a {Stomper::Connection} object.
  module V1_0
    # Stomp 1.0 ack/nack semantics
    module Acking
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
    
    # Stomp 1.0 heartbeating semantics.
    module Heartbeating
      # No-op for Stomp 1.0.
      def beat
      end

      # Stomp 1.0 {Stomper::Connection connections} are alive if they are
      # +connected?+
      # @return [true, false]
      # @see #dead?
      def alive?
        connected?
      end

      # A {Stomper::Connection connection} is dead if it is not +alive?+
      # @return [true, false]
      # @see #alive?
      def dead?
        !alive?
      end
    end
  end
  
  # Provides the Stomp 1.1 protocol specific interface
  # for a {Stomper::Connection} object.
  module V1_1
    # Stomp 1.1 ack/nack semantics
    module Acking
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
    
    # Stomp 1.1 heartbeating semantics
    module Heartbeating
      # Send a heartbeat to the broker
      def beat
        transmit ::Stomper::Frame.new
      end

      # Stomp 1.1 {Stomper::Connection connections} are alive if they are
      # +connected?+ and are meeting their negotiated heart-beating obligations.
      # @return [true, false]
      # @see #dead?
      def alive?
        connected? && client_alive? && broker_alive?
      end
      
      # Maximum number of milliseconds that can pass between frame / heartbeat
      # transmissions before we consider the client to be dead.
      # @return [Fixnum]
      def heartbeat_client_limit
        unless defined?(@heartbeat_client_limit)
          @heartbeat_client_limit = heartbeating[0] > 0 ? (1.1 * heartbeating[0]) : 0
        end
        @heartbeat_client_limit
      end
      
      # Maximum number of milliseconds that can pass between frames / heartbeats
      # received before we consider the broker to be dead.
      # @return [Fixnum]
      def heartbeat_broker_limit
        unless defined?(@heartbeat_broker_limit)
          @heartbeat_broker_limit = heartbeating[1] > 0 ? (1.1 * heartbeating[1]) : 0
        end
        @heartbeat_broker_limit
      end
      
      # Returns true if the client is alive. Client is alive if client heartbeating
      # is disabled, or the number of milliseconds that have passed since last
      # transmission is less than or equal to {#heartbeat_client_limit client} limit
      # @return [true,false]
      # @see #heartbeat_client_limit
      # @see #broker_alive?
      def client_alive?
        # Consider some benchmarking to determine if this is faster than
        # re-writing the method after its first invocation.
        heartbeat_client_limit == 0 ||
          duration_since_transmitted <= heartbeat_client_limit
      end
      
      # Returns true if the broker is alive. Broker is alive if broker heartbeating
      # is disabled, or the number of milliseconds that have passed since last
      # receiving is less than or equal to {#heartbeat_broker_limit broker} limit
      # @return [true,false]
      # @see #heartbeat_broker_limit
      # @see #client_alive?
      def broker_alive?
        heartbeat_broker_limit == 0 ||
          duration_since_received <= heartbeat_broker_limit
      end
    end
  end
  
  # A mapping between negotiated protocol versions and modules to include
  # to support said version.
  EXTEND_BY_VERSION = {
    '1.0' => [ ::Stomper::Extensions::Protocols::V1_0::Acking ],
    '1.1' => [ ::Stomper::Extensions::Protocols::V1_1::Acking,
               ::Stomper::Extensions::Protocols::V1_1::Heartbeating ]
  }
end