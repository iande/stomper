module URI
  class STOMP < ::URI::Generic
    def initialize(*args)
      super
    end

    def create_socket
      ::Stomper::StompSocket.new(self)
    end

    def open
      
    end
  end

  class STOMP_SSL < STOMP
    def initialize(*args)
      super
    end

    def create_socket
      ::Stomper::SecureStompSocket.new(self)
    end

    def self.to_s
      # Why do I get the feeling this might be a bad idea?
      "URI::STOMP+SSL"
    end
  end

  @@schemes['STOMP'] = STOMP
  @@schemes['STOMP+SSL'] = STOMP_SSL
end