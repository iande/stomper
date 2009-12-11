# A basic stomp client connection.  This class is not meant to be synchronized
# nor is it meant to be reliable.  We will layer that functionality atop
# this class with the Client and ReliableConnection classes respectively.
# The only state I want instances of this class to maintain are the base
# uri (defined through initialize and then left alone) and the raw socket
# to the stomp server.  Most higher level code should make use of the Client
# class intead of this.

module Stomper
  class Connection
    attr_reader :uri
    attr_reader :socket

    def initialize(uri, opts = {})
      connect_now = opts.delete(:connect_now) { true }
      @uri = URI.parse(uri)
      #connect_now = opts.delete(:connect_now) { true }
      # ActiveMQ seems to suggest using port 61612 for stomp+ssl connections
      # As do some other Stomp resources.
      @uri.port = (@uri.scheme == "stomp") ? 61613 : 61612 if @uri.port.nil?
      # Can only really happen with: stomp(+ssl):///, but URI won't complain
      # when receiving that, so we need to accommodate it.
      @uri.host = 'localhost' if @uri.host.nil?
      @uri.freeze
      #raise ArgumentError, "secure connections not currently supported" if @uri.scheme == "stomp+ssl"
      #connect if connect_now
      @use_ssl = (@uri.scheme == "stomp+ssl")
      if @use_ssl
        @ssl_context = OpenSSL::SSL::SSLContext.new
        @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @connected = false
      connect if connect_now
    end

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

    # This method should be viewed as "higher level"
    # IE: connected? should return true when an instance expects that it is
    # still connected, and false when the instance has given up the ghost.
    # For the basic connection, this implementation is perfectly fine.
    # For the reliable version, it should only return true if we have
    # either explicitly disconnected, or we have given up trying to be reliable.
    def connected?
      #!(@socket.closed? || @socket.eof?)
      @connected && @socket && !@socket.closed?
    end

    def close
      @socket.close
    ensure
      @connected = false
    end

    # Try to be nice about disconnecting by sending a DISCONNECT frame
    # then closing the connection
    def disconnect
      transmit(Stomper::Frames::Disconnect.new)
    ensure
      close
    end

    def transmit(frame)
      @socket.write(frame.to_stomp)
    end

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
