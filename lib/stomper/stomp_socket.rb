module Stomper
  class StompSocket < DelegateClass(TCPSocket)
    DEFAULT_PORT = 61613

    def initialize(uri)
      uri.host ||= 'localhost'
      uri.port ||= DEFAULT_PORT
      @socket = TCPSocket.new(uri.host, uri.port)
      super(@socket)
    end
  end
end
