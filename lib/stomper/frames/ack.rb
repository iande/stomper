module Stomper
  module Frames
    class Ack < Stomper::Frames::ClientFrame
      def initialize(message_id, headers={})
        super('ACK', headers)
        @headers["message-id"] = message_id
      end

      def self.ack_for(message, headers = {})
        if message.is_a?(Message)
          headers['transaction'] = message.headers.transaction if message.headers.transaction
          new(message.id, headers)
        else
          new(message.to_s)
        end
      end
    end
  end
end
