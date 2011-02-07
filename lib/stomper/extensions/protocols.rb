# -*- encoding: utf-8 -*-

# Namespace for specific protocl version extensions.
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
    def ack(message_or_id, *args)
      headers = args.last.is_a?(Hash) ? args.pop : {}
      transmit ::Stomper::Frame.new('ACK', headers)
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
    # Transmits an ACK frame to the broker to acknowledge that a corresponding
    # MESSAGE frame has been processed by the client. The first argument must
    # be either the MESSAGE frame you wish to acknowledge or its ID. If the
    # negotiated version protocol is 1.1 or greater, the broker also requires
    # that the subscription ID be included in the headers. If a MESSAGE frame
    # has been provided, this method will try to use its +subscription+ header.
    # If that fails, or a message ID was supplied, the subscription ID must be
    # passed as the second parameter, or included in the headers hash. If
    # the final parameter to this method is a hash, it will used to apply
    # additional headers to the generated frame.
    # @note The requirements of this method vary depending upon which protocol
    #   version is being used.
    # @param [Stomper::Frame, String] message_or_id the MESSAGE frame, or ID, to acknowledge
    # @return [Stomper::Frame] the ACK frame sent to the broker
    # @raise [ArgumentError] if the negotiated protocol
    #   version is 1.1 and the subscription id was not provided and cannot be inferred.
    # @example Gonna need some examples for this one...
    def ack(message_or_id, *args)
      headers = args.last.is_a?(Hash) ? args.pop : {}
      # raise ::ArgumentError, 'subscription ID could not be determined'
    end

    # Transmits a NACK frame to the broker to indicate that a corresponding
    # MESSAGE frame was not processed by the client. The first argument must
    # be either the MESSAGE frame you wish to indicate was not processed or its ID.
    # The Stomp 1.1 protocol also requires that the corresponding subscription ID
    # be included in the headers. If a MESSAGE frame has been provided, this
    # method will try to use its +subscription+ header. If that fails, or a
    # message ID was supplied, the subscription ID must be passed as the second
    # parameter, or included in the headers hash. If the final parameter to this
    # method is a hash, it will used to apply additional headers to the generated frame.
    # @note This method is only available if the client and broker are using the
    #   Stomp 1.1 protocol version.
    # @param [Stomper::Frame, String] message_or_id the MESSAGE frame, or ID, to un-acknowledge
    # @return [Stomper::Frame] the NACK frame sent to the broker
    # @raise [Stomper::Errors::UnsupportedCommandError] if the negotiated protocol
    #   version is 1.0
    # @raise [ArgumentError] if the negotiated protocol
    #   version is 1.1 and the subscription id was not provided and cannot be inferred.
    # @example Gonna need some examples for this one...
    def nack(message_or_id, *args)
      # raise ::ArgumentError, 'subscription ID could not be determined'
    end
  end
  
  # A mapping between negotiated protocol versions and modules to include
  # to support said version.
  EXTEND_BY_VERSION = {
    '1.0' => [ ::Stomper::Extensions::Protocols::V1_0 ],
    '1.1' => [ ::Stomper::Extensions::Protocols::V1_1 ]
  }
end