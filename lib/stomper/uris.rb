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
    
    # Creates a TCP socket connection to the host and port specified by
    # this URI.
    # @return Stomper::Sockets::TCP
    def create_socket(*args)
      ::Stomper::Sockets::TCP.new(self.host||'localhost', self.port)
    end
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
    
    # Creates a SSL socket connection to the host and port specified by
    # this URI. If a hash is included as the last argument to the call,
    # it will be passed along as SSL options to {Stomper::Sockets::SSL#initialize}
    # @return Stomper::Sockets::SSL
    def create_socket(*args)
      ::Stomper::Sockets::SSL.new(self.host||'localhost', self.port,
        (args.last.is_a?(Hash) ? args.pop : {}))
    end
  end
  
  # Add these classes to the URI @@schemas hash, thus making URI aware
  # of these two handlers.
  @@schemes['STOMP'] = STOMP
  @@schemes['STOMP+SSL'] = STOMP_SSL
end
