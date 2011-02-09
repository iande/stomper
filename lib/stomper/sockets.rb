# -*- encoding: utf-8 -*-

# Socket helpers.
module Stomper::Sockets
  
  # A wrapper for an SSL Socket that tidies up the SSL specifics so
  # our Connection library isn't troubled by them.
  class SSL < DelegateClass(::OpenSSL::SSL::SSLSocket)
    include ::Stomper::FrameIO
    def initialize(host, port, *args)
      #self.extend ::Stomper::FrameIO
      # This all needs to be configurable!
      raise "Not until we can configure this jazz"
      @context = OpenSSL::SSL::SSLContext.new
      @context.verify_mode = OpenSSL::SSL::VERIFY_NONE

      tcp_sock = TCPSocket.new(host, port)
      @socket = OpenSSL::SSL::SSLSocket.new(tcp_sock, @context)
      @socket.sync_close = true
      @socket.connect
      super(@socket)
    end
    
    # Passes the :ready? message on to the socket's underlying io object.
    def ready?; @socket.io.ready?; end
    
    # Passes the :shutdown message on to the socket's underlying io object.
    def shutdown(mode=2); @socket.io.shutdown(mode); end
  end
  
  # A wrapper for an TCP Socket that tidies up the specifics so
  # our Connection library isn't troubled by them.
  class TCP < DelegateClass(::TCPSocket)
    include ::Stomper::FrameIO
    def initialize(host, port, *args)
      #self.extend ::Stomper::FrameIO
      @socket = TCPSocket.new(host, port)
      super(@socket)
    end
  end
end
