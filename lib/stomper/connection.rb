module Stomper
  # A low level connection to a Stomp message broker.
  # Instances of Connection are not synchronized and thus not
  # directly thread safe.  This is a deliberate decision as instances of
  # Stomper::Client are the preferred way of communicating with
  # Stomp message broker services.
  class Connection
    attr_reader :uri
    attr_reader :socket

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
    # The +opts+ parameter is a hash of options, and can include:
    #
    # [:connect_now] Immediately connect to the broker when a new instance is created (default: true)
    def initialize(uri, opts = {})
      connect_now = opts.delete(:connect_now) { true }
      @uri = (uri.is_a?(URI) && uri) or URI.parse(uri)
      @uri.port = (@uri.scheme == "stomp+ssl") ? 61612 : 61613 if @uri.port.nil?
      @uri.host = 'localhost' if @uri.host.nil?
      @uri.freeze
      @use_ssl = (@uri.scheme == "stomp+ssl")
      if @use_ssl
        @ssl_context = OpenSSL::SSL::SSLContext.new
        @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @connected = false
      connect if connect_now
    end


    # Connects to the broker specified by the +uri+ attribute.
    # By default, this method is invoked when a new Stomper::Connection
    # is created.
    #
    # See also: new
    def connect
      s = TCPSocket.open(@uri.host, @uri.port)
      if @use_ssl
        s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
        s.sync_close = true
        s.connect
      end
      @socket = s
      transmit Stomper::Frames::Connect.new(@uri.user, @uri.password)
      # Block until the first frame is received
      connect_frame = receive(true)
      @connected = connect_frame.instance_of?(Stomper::Frames::Connected)
    end

    # Returns true when there is an open connection
    # established to the broker.
    def connected?
      # FIXME: @socket.eof? appears to block or otherwise "wonk out", not sure
      # why yet.
      #!(@socket.closed? || @socket.eof?)
      @connected && @socket && !@socket.closed?
    end

    # Immediately closes the connection to the broker.
    #
    # See also: disconnect
    def close
      @socket.close
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

    # Converts an instance of Stomper::Frames::ClientFrame into
    # a string conforming to the Stomp protocol and sends it
    # to the broker.
    def transmit(frame)
      @socket.write(frame.to_stomp)
    end

    # Receives a single Stomper::Frames::ServerFrame from the broker.
    # If the frame received is known to the Stomper library, an instance of
    # the appropriate subclass will be returned (eg: Stomper::Frames::Message),
    # otherwise an instance of Stomper::Frames::ServerFrame is returned with
    # the +command+ attribute set to the frame type.
    # If the +blocking+ parameter is set to true, +receive+ will
    # block until there is a frame available from the server, otherwise if no frame
    # is currently available, +nil+ is returned.
    #
    # If an incoming message is malformed (not terminated with a NULL (\0)
    # character, or has an incorrectly specified +content+-+length+ header,
    # this method will raise an exception. [Type the exception, don't rely on
    # a basic RuntimeError or whatever the default is.]
    def receive(blocking=false)
      command = ''
      while (ready? || blocking) && (command = @socket.gets)
        command.chomp!
        break if command.size > 0
      end
      # If we got a command, continue on, potentially blocking until
      # the entire message is received, otherwise we bail out now.
      return nil if command.nil? || command.size == 0
      headers = {}
      while (line = @socket.gets)
        line.chomp!
        break if line.size == 0
        delim = line.index(':')
        if delim
          key = line[0..(delim-1)]
          val = line[(delim+1)..-1]
          headers[key] = val
        end
      end
      body = nil
      # Have we been given a content length?
      if headers['content-length']
        body = @socket.read(headers['content-length'].to_i)
        raise "Invalid message terminator or content-length header" if socket_c_to_i(@socket.getc) != 0
      else
        body = ''
        # We read until we find the first nil character
        while (c = @socket.getc)
          # Both Ruby 1.8 and 1.9 should support this even though the behavior
          # of getc is different between the two.  However, jruby is particular
          # about this.  And that sucks.
          break if socket_c_to_i(c) == 0
          body << socket_c_to_chr(c)
        end
      end
      # Messages should be forever immutable.
      Stomper::Frames::ServerFrame.build(command, headers, body).freeze
    end

    private
    def ready?
      (@use_ssl) ? @socket.io.ready? : @socket.ready?
    end

    def socket_c_to_i(c)
      if c.respond_to?(:ord)
        def socket_c_to_i(char); char.ord; end
        c.ord
      else
        def socket_c_to_i(char); char; end
        c
      end
    end
    def socket_c_to_chr(c)
      if c.respond_to?(:chr)
        def socket_c_to_chr(char); char.chr; end
        c.chr
      else
        def socket_c_to_chr(char); char; end
        c
      end
    end
  end
end
