module Stomper
  module Frames
    class Disconnect < Stomper::Frames::ClientFrame
      def initialize
        super('DISCONNECT')
      end
    end
  end
end
