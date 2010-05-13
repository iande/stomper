# To change this template, choose Tools | Templates
# and open the template in the editor.

module Stomper
  module Sockets
    class SSL < DelegateClass(OpenSSL::SSL::SSLSocket)
      def initialize(host, port, *args)
        @context = OpenSSL::SSL::SSLContext.new
        @context.verify_mode = OpenSSL::SSL::VERIFY_NONE

        tcp_sock = TCPSocket.new(host, port)
        @socket = OpenSSL::SSL::SSLSocket.new(tcp_sock, @ssl_context)
        @socket.sync_close = true
        @socket.connect
        super(@socket)
      end

      def ready?
        @socket.io.ready?
      end
    end

    class TCP < DelegateClass(TCPSocket)
      def initialize(host, port, *args)
        @socket = TCPSocket.new(host, port)
        super(@socket)
      end
    end
  end
end
