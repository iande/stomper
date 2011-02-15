# -*- encoding: utf-8 -*-

# Socket helpers.
module Stomper::Sockets
  
  # A wrapper for an SSL Socket that tidies up the SSL specifics so
  # our Connection library isn't troubled by them.
  class SSL < DelegateClass(::OpenSSL::SSL::SSLSocket)
    DEFAULT_SSL_OPTIONS = {
      :verify_mode => ::OpenSSL::SSL::VERIFY_PEER |
        ::OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT,
      :ca_file => nil,
      :ca_path => nil,
      :cert => nil,
      :key => nil,
      :post_connection_check => true
    }
    
    def initialize(host, port, opts={})
      ssl_opts = DEFAULT_SSL_OPTIONS.merge(opts)

      @context = ::OpenSSL::SSL::SSLContext.new
      post_check = ssl_opts.delete(:post_connection_check)
      post_check_host = (post_check == true) ? host : post_check
      
      DEFAULT_SSL_OPTIONS.keys.each do |k|
        @context.__send__(:"#{k}=", ssl_opts[k]) if ssl_opts.key?(k)
      end

      tcp_sock = ::TCPSocket.new(host, port)
      @socket = ::OpenSSL::SSL::SSLSocket.new(tcp_sock, @context)
      @socket.sync_close = true
      @socket.connect
      if post_check_host
        @socket.post_connection_check(post_check_host)
      end
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
    def initialize(host, port)
      @socket = TCPSocket.new(host, port)
      super(@socket)
    end
  end
end
