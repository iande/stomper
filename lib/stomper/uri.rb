module URI
  class STOMP < ::URI::Generic
    # Got to love the magic of URI::Generic.
    # By setting this constant, you ensure that all
    # Stomp URI's have this port if one isn't specified.
    DEFAULT_PORT = 61613

    def initialize(*args)
      super
    end

    def create_socket
      ::Stomper::Sockets::TCP.new(self.host||'localhost', self.port)
    end

    def open(*args)
      conx = Stomper::Connection.open(self)
      conx.extend Stomper::OpenUriInterface
      if block_given?
        begin
          yield conx
        ensure
          conx.disconnect
        end
      end
      conx
    end
  end

  class STOMP_SSL < STOMP
    DEFAULT_PORT = 61612

    def initialize(*args)
      super
    end

    # Creates a socket from the URI
    def create_socket
      ::Stomper::Sockets::SSL.new(self.host||'localhost', self.port)
    end

    # The +uri+ standard library resolves string URI's to concrete classes
    # by matching the string's schema to the name of a subclass of URI::Generic.
    # Ruby doesn't support '+' symbols in a class name, so the only way to handle
    # schemas with odd characters is to override the "to_s" function of the class.
    #
    # Why do I get the feeling this might be a bad idea?
    def self.to_s
      "URI::STOMP+SSL"
    end
  end

  @@schemes['STOMP'] = STOMP
  @@schemes['STOMP+SSL'] = STOMP_SSL
end