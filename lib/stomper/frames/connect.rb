module Stomper
  module Frames
    class Connect < Stomper::Frames::ClientFrame
      def initialize(username='', password='')
        super('CONNECT')
        @headers['login'] = username
        @headers['passcode'] = password
      end
    end
  end
end
