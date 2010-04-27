module Stomper
  module Frames
    # Encapsulates an "ERROR" server side frame for the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Error < Stomper::Frames::ServerFrame
      # This class is a factory for all incoming ERROR frames.
      factory_for :error

      # Creates a new Error frame with the supplied +headers+ and +body+
      def initialize(headers, body)
        super('ERROR', headers, body)
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
