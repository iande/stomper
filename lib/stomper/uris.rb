# -*- encoding: utf-8 -*-

# Subclasses of URI::Generic to ease working with Stomp URIs.
module URI
  # This class encapsulates a URI with a schema of "stomp".  For example,
  # "stomp://host.domain.tld"
  class STOMP < ::URI::Generic
    # Specifies the default port of a standard Stomp connection. Any URI
    # without explicit port specified will use this value instead.
    #
    # @note The Stomp specification does not define any default ports, this port
    #   has been chosen because it is fairly common amongst brokers that
    #   provide a Stomp interface, such as Apache's ActiveMQ.
    DEFAULT_PORT = 61613
    
    # Creates a TCP/IP socket for the Stomp broker pointed to by this URI.
    # The socket includes the {::Stomper::FrameIO} mixin, making it suitable
    # for high level frame writing and reading.
    #
    # @return [nil]
    def create_socket
      self.class.socket_factory.new(self.host||'localhost', self.port)
    end

    # Opens a connection to the Stomp broker pointed to by this URI. This
    # method is provided to allow the +open-uri+ to work with Stomper
    # connections through +open('stomp://host.domain.tld')+.  If a block
    # is given, the connection will be closed when the block completes.
    #
    # @return [Stomper::Connection]
    def open(*args)
      conx = ::Stomper::Connection.new(self)
      conx.connect
      if block_given?
        begin
          yield conx
        ensure
          conx.disconnect
        end
      end
      conx
    end
    
    # This method provides the class to use for constructing new sockets for
    # the brokers referenced by STOMP URIs.
    # @return [Stomper::Sockets::TCP]
    def self.socket_factory; ::Stomper::Sockets::TCP; end
  end
  
  # This class encapsulates a URI with a schema of "stomp+ssl".  For example,
  # "stomp+ssl://host.domain.tld"
  class STOMP_SSL < ::URI::STOMP
    # Specifies the default port of a standard Stomp connection. Any URI
    # without explicit port specified will use this value instead.
    #
    # @note The Stomp specification does not define any default ports, this port
    #   has been chosen because it is fairly common amongst brokers that
    #   provide a Secure Stomp interface, such as Apache's ActiveMQ.
    DEFAULT_PORT = 61612
    
    # This method provides the class to use for constructing new sockets for
    # the brokers referenced by STOMP_SSL URIs.
    # @return [Stomper::Sockets::SSL]
    def self.socket_factory; ::Stomper::Sockets::SSL; end
  end
  
  # Add these classes to the URI @@schemas hash, thus making URI aware
  # of these two handlers.
  @@schemes['STOMP'] = STOMP
  @@schemes['STOMP+SSL'] = STOMP_SSL
end
