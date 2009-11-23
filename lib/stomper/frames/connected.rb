module Stomper
  module Frames
    class Connected < Stomper::Frames::ServerFrame
      factory_for :connected

      def initialize(headers, body)
        super('CONNECTED', headers, body)
      end

      def session
        @headers.session
      end
    end
  end
end
