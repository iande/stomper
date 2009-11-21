module Stomper
  module Frames
    class Unsubscribe < Stomper::Frames::ClientFrame
      def initialize(destination, headers={})
        super('UNSUBSCRIBE', headers)
        @headers['destination'] = destination
      end

      def id
        @headers['id']
      end
    end
  end
end
