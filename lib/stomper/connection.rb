module Stomper
  # A low level connection to a Stomp message broker.
  # Instances of Connection are not synchronized and thus not
  # directly thread safe.  This is a deliberate decision as instances of
  # Stomper::Client are the preferred way of communicating with
  # Stomp message broker services.
  class Connection
    attr_reader :uri
    attr_reader :socket

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
    #
    # TODO: Refactor out the SSL business into a separate connection wrapper.
    def initialize(uri)
      @uri = (uri.is_a?(URI) && uri) || URI.parse(uri)
      @use_ssl = (@uri.scheme == "stomp+ssl")
      @uri.host ||= 'localhost'
      if @use_ssl
        @uri.port ||= 61612
        @ssl_context = OpenSSL::SSL::SSLContext.new
        @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        @uri.port ||= 61613
      end
      @uri.freeze
      @connected = false
      @writer = @reader = nil
    end


    # Connects to the broker specified by the +uri+ attribute.
    # By default, this method is invoked when a new Stomper::Connection
    # is created.
    #
    # See also: new
    def connect
      stomp_socket = TCPSocket.open(@uri.host, @uri.port)
      if @use_ssl
        stomp_socket = OpenSSL::SSL::SSLSocket.new(stomp_socket, @ssl_context)
        stomp_socket.sync_close = true
        stomp_socket.connect
      end
      @socket = stomp_socket
      @writer = Stomper::FrameWriter.new(@socket)
      @reader = Stomper::FrameReader.new(@socket)
      transmit Stomper::Frames::Connect.new(@uri.user, @uri.password)
      # Block until the first frame is received
      connect_frame = receive
      @connected = connect_frame.instance_of?(Stomper::Frames::Connected)
    end

    # Returns true when there is an open connection
    # established to the broker.
    def connected?
      @connected && @socket && !@socket.closed?
    end

    # Immediately closes the connection to the broker, without the
    # formality of sending a Disconnect frame.
    #
    # See also: disconnect
    def close
      @socket.close if @socket
    ensure
      @connected = false
    end

    # Transmits a Stomper::Frames::Disconnect frame to the broker
    # then terminates the connection by invoking +close+.
    #
    # See also: close
    def disconnect
      transmit(Stomper::Frames::Disconnect.new)
    ensure
      close
    end

    # Transmits the a Stomp Frame to the connected Stomp broker by
    # way of an internal FrameWriter.  If an exception is raised
    # during the transmission, the connection will be forcibly closed
    # and the exception will be propegated.
    def transmit(frame)
      begin
        @writer.put_frame(frame)
      rescue Exception => ioerr
        self.close
        raise ioerr
      end
    end

    # Receives the next Stomp Frame from an internal FrameReader that
    # wraps the underlying Stomp broker connection.  If an exception is raised
    # during the fetch, the connection will be forcibly closed and the exception
    # will be propegated.
    def receive()
      begin
        @reader.get_frame
      rescue Exception => ioerr
        self.close
        raise ioerr
      end
    end
  end
end
