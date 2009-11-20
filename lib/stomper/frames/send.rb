module Stomper
  module Frames
    class Send < Stomper::Frames::ClientFrame
      def initialize(destination, body, headers={})
        super('SEND', headers)
        @headers['destination'] = destination
        @body = body
      end
    end
  end
end
