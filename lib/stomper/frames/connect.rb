module Stomper
  module Frames
    # Encapsulates a "CONNECT" frame from the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class Connect < Stomper::Frames::ClientFrame
      def initialize(username='', password='', headers={})
        super('CONNECT', headers)
        @headers.login = username
        @headers.passcode = password
      end
    end
  end
end
