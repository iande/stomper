module Stomper
  module Frames
    class Error < Stomper::Frames::ServerFrame
      frame_factory :error
      attr_reader :message

      def initialize(headers, body)
        super('ERROR', headers, body)
        @message = headers['message']
      end
    end
  end
end
