module Stomper
  # TODO: Rewrite this.  Soon it will not be true as we are removing Client.
  # 
  # A low level connection to a Stomp message broker.
  # Instances of Connection are not synchronized and thus not
  # directly thread safe.  This is a deliberate decision as instances of
  # Stomper::Client are the preferred way of communicating with
  # Stomp message broker services.
  class Connection
    attr_reader :uri

    class << self
      def connect(uri)
        connex = new(uri)
        connex.connect
        connex
      end
      alias_method :open, :connect
    end

    # Creates a new connection to the Stomp broker specified by +uri+.
    # The +uri+ parameter may be either a URI object, or something that can
    # be parsed by URI.parse, such as a string.
    # Some examples of acceptable +uri+ forms include:
    # [stomp:///] Connection will be made to 'localhost' on port 61613 with no login credentials.
    # [stomp+ssl:///] Same as above, but connection will be made on port 61612 and wrapped by SSL.
    # [stomp://user:pass@host.tld] Connection will be made to 'host.tld', authenticating as 'user' with a password of 'pass'.
    # [stomp://user:pass@host.tld:86753] Connection will be made to 'host.tld' on port 86753, authenticating as above.
    # [stomp://host.tld:86753] Connection will be made to 'host.tld' on port 86753, with no authentication.
    #
    # In order to wrap the connection with SSL, the schema of +uri+ must be 'stomp+ssl';
    # however, if SSL is not required, the schema is essentially ignored.
    # The default port for the 'stomp+ssl' schema is 61612, all other schemas
    # default to port 61613.
    def initialize(uri)
      @uri = (uri.is_a?(URI) && uri) || URI.parse(uri)
      raise ArgumentError, 'Expected URI schema to be one of stomp or stomp+ssl' unless @uri.respond_to?(:create_socket)
      @connected = false
      @writer = @reader = nil
      #@state = Stomper::SocketState.new
    end


    # Connects to the broker specified by the +uri+ attribute.
    # By default, this method is invoked when a new Stomper::Connection
    # is created.
    #
    # See also: new
    def connect
      @connected = false
      @socket = @uri.create_socket
      transmit Stomper::Frames::Connect.new(@uri.user, @uri.password)
      @connected = receive.instance_of?(Stomper::Frames::Connected)
    end

    # Returns true when there is an open connection
    # established to the broker.
    def connected?
      @connected && @socket && !@socket.closed?
    end

    # Transmits a Stomper::Frames::Disconnect frame to the broker
    # then terminates the connection by invoking +close+.
    def disconnect
      @connected = false
      transmit(Stomper::Frames::Disconnect.new)
    ensure
      close_socket
    end

    alias_method :close, :disconnect

    # Transmits the a Stomp Frame to the connected Stomp broker by
    # way of an internal FrameWriter.  If an exception is raised
    # during the transmission, the connection will be forcibly closed
    # and the exception will be propegated.
    def transmit(frame)
      begin
        @socket.transmit_frame(frame)
      rescue Exception => ioerr
        close_socket :lost_connection
        raise ioerr
      end
    end

    # Receives the next Stomp Frame from an internal FrameReader that
    # wraps the underlying Stomp broker connection.  If an exception is raised
    # during the fetch, the connection will be forcibly closed and the exception
    # will be propegated.
    def receive()
      begin
        @socket.receive_frame
      rescue Exception => ioerr
        close_socket :lost_connection
        raise ioerr
      end
    end

    # Immediately closes the connection to the broker, without the
    # formality of sending a Disconnect frame.
    #
    # See also: disconnect
    def close_socket(conx_state = :disconnected)
      @socket.shutdown(2)
      @socket.close if @socket
    end

    include ::Stomper::ClientInterface
    include ::Stomper::TransactorInterface
    include ::Stomper::SubscriberInterface
  end
end
