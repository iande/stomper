module Stomper
  module Frames
    class Send < Stomper::Frames::ClientFrame
      def initialize(destination, body, headers={})
        super('SEND', headers, body)
        @headers.destination = destination
      end
    end
  end
end
