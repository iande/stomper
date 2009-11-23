module Stomper
  module Frames
    class Connect < Stomper::Frames::ClientFrame
      def initialize(username='', password='', headers={})
        super('CONNECT', headers)
        @headers.login = username
        @headers.passcode = password
      end
    end
  end
end
