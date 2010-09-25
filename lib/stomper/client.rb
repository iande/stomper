module Stomper
  module Client
    # Sends a string message specified by +body+ to the appropriate stomp
    # broker destination given by +destination+.  Additional headers for the
    # message may be specified by the +headers+ hash where the key is the header
    # property and the value is the corresponding property's value.  The
    # keys of +headers+ may be symbols or strings.
    #
    # Examples:
    #
    #   client.send("/topic/whatever", "hello world")
    #
    #   client.send("/queue/some/destination", "hello world", { :persistent => true })
    #
    def send(destination, body, headers={})
      transmit(Stomper::Frames::Send.new(destination, body, headers))
    end

    # Acknowledge to the stomp broker that a given message was received.
    # The +id_or_frame+ parameter may be either the message-id header of
    # the received message, or an actual instance of Stomper::Frames::Message.
    # Additional headers may be specified through the +headers+ hash.
    #
    # Examples:
    #
    #   client.ack(received_message)
    #
    #   client.ack("message-0001-00451-003031")
    #
    def ack(id_or_frame, headers={})
      transmit(Stomper::Frames::Ack.ack_for(id_or_frame, headers))
    end
  end
end
