module Stomper
  class SecureStompSocket < DelegateClass(OpenSSL::SSL::SSLSocket)
    DEFAULT_PORT = 61612

    def initialize(uri)
      uri.host ||= 'localhost'
      uri.port ||= DEFAULT_PORT

      @context = OpenSSL::SSL::SSLContext.new
      @context.verify_mode = OpenSSL::SSL::VERIFY_NONE

      tcp_sock = TCPSocket.new(uri.host, uri.port)
      @socket = OpenSSL::SSL::SSLSocket.new(tcp_sock, @ssl_context)
      @socket.sync_close = true
      @socket.connect
      super(@socket)
    end

    def ready?
      @socket.io.ready?
    end
  end
end
