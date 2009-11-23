module Stomper
  module Frames
    class Error < Stomper::Frames::ServerFrame
      factory_for :error

      def initialize(headers, body)
        super('ERROR', headers, body)
      end

      def message
        @headers.message
      end
    end
  end
end
