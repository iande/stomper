module Stomper
  module Frames
    # Encapsulates an "ERROR" server side frame for the Stomp Protocol.
    class Error < Stomper::Frames::ServerFrame

      # Creates a new Error frame with the supplied +headers+ and +body+
      def initialize(headers, body)
        super(headers, body)
      end

      # Returns the message responsible for the generation of this Error frame,
      # if applicable.
      #
      # This is a convenience method for:
      # frame.headers[:message]
      def message
        @headers[:message]
      end
    end
  end
end
