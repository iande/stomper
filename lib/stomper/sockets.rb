module Stomper
  module Sockets
    class SSL < DelegateClass(OpenSSL::SSL::SSLSocket)
      include FrameReader
      include FrameWriter

      def initialize(host, port, *args)
        @context = OpenSSL::SSL::SSLContext.new
        @context.verify_mode = OpenSSL::SSL::VERIFY_NONE

        tcp_sock = TCPSocket.new(host, port)
        @socket = OpenSSL::SSL::SSLSocket.new(tcp_sock, @context)
        @socket.sync_close = true
        @socket.connect
        super(@socket)
      end

      def ready?
        @socket.io.ready?
      end
      
      def shutdown(mode=2)
        @socket.io.shutdown(mode)
      end
    end

    class TCP < DelegateClass(TCPSocket)
      include FrameReader
      include FrameWriter

      def initialize(host, port, *args)
        @socket = TCPSocket.new(host, port)
        super(@socket)
      end
    end
  end
end
