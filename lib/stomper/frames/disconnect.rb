module Stomper
  module Frames
    class Disconnect < Stomper::Frames::ClientFrame
      def initialize(headers={})
        super('DISCONNECT', headers)
      end
    end
  end
end
