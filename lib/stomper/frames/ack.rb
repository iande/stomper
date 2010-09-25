module Stomper
  module Frames
    # Encapsulates an "ACK" frame from the Stomp Protocol.
    class Ack < Stomper::Frames::ClientFrame
      def initialize(message_id, headers={})
        super(headers.merge({ :'message-id' => message_id }))
      end

      # Creates a new Ack instance that corresponds to an acknowledgement
      # of the supplied +message+, with any additional +headers+.  The
      # +message+ parameter may be an instance of Stomper::Frames::Message, or
      # a message id.  If +message+ is an instance of Stomper::Frames::Message
      # and was exchanged as part of a transaction, the transaction header from
      # +message+ will be injected into the newly created Ack object's headers.
      def self.ack_for(message, headers = {})
        if message.is_a?(Message)
          headers[:transaction] = message.headers[:transaction] if message.headers[:transaction]
          new(message.id, headers)
        else
          new(message.to_s)
        end
      end
    end
  end
end
