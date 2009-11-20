module Stomper
  module Frames
    class Connected < Stomper::Frames::ServerFrame
      frame_factory :connected
      attr_reader :session

      def initialize(headers, body)
        super('CONNECTED', headers, body)
        @session = headers['session']
      end
    end
  end
end
