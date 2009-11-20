# A basic stomp client connection.  This class is not meant to be synchronized
# nor is it meant to be reliable.  We will layer that functionality atop
# this class with the Client and ReliableConnection classes respectively.
# The only state I want instances of this class to maintain are the base
# uri (defined through initialize and then left alone) and the raw socket
# to the stomp server.  Most higher level code should make use of the Client
# class intead of this.

module Stomper
  class BasicConnection
    attr_reader :uri
    attr_reader :socket

    def initialize(host_or_uri, port=nil, user=nil, pass=nil, secure=false)
      if host_or_uri =~ /^stomp[^:]*:\/\//
        @uri = URI.parse(host_or_uri)
      else
        scheme = (secure) ? "stomp+ssl" : "stomp"
        creds = (user.nil? || pass.nil?) ? "" : "#{user}:#{pass}@"
        hostport = (port.nil?) ? host_or_uri : "#{host_or_uri}:#{port}"
        @uri = URI.parse("#{scheme}://#{creds}#{hostport}")
      end
      # ActiveMQ seems to suggest using port 61612 for stomp+ssl connections
      # As do some other Stomp resources.
      @uri.port = (@uri.scheme == "stomp") ? 61613 : 61612 if @uri.port.nil?
      # Can only really happen with: stomp(+ssl):///, but URI won't complain
      # when receiving that, so we need to accommodate it.
      @uri.host = 'localhost' if @uri.host.nil?
      @uri.freeze
      raise ArgumentError, "secure connections not currently supported" if @uri.scheme == "stomp+ssl"
      connect
    end

    # Convenience method.  I don't know who it is convenient for, but the original
    # Stomp library provided it, so we shall, too.
    def BasicConnection.open(host_or_uri, port=nil, user=nil, pass=nil, secure=false)
      new(host_or_uri, port, user, pass, secure)
    end

    def connect
      @socket = TCPSocket.new(@uri.host, @uri.port)
      # Let's see how much this screws things up!
      #@socket.nonblock= true
      transmit Stomper::Frames::Connect.new(@uri.user, @uri.password)
    end

    # This method should be viewed as "higher level"
    # IE: connected? should return true when an instance expects that it is
    # still connected, and false when the instance has given up the ghost.
    # For the basic connection, this implementation is perfectly fine.
    # For the reliable version, it should only return true if we have
    # either explicitly disconnected, or we have given up trying to be reliable.
    def connected?
      #!(@socket.closed? || @socket.eof?)
      !@socket.closed?
    end

    def close
      @socket.close
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

    def receive
      command = ''
      while @socket.ready? && (command = @socket.gets)
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
        raise "Invalid message terminator or content-length header" if @socket.getc.ord != 0
      else
        body = ''
        # We read until we find the first nil character
        while (c = @socket.getc)
          # Both Ruby 1.8 and 1.9 should support this even though the behavior
          # of getc is different between the two.
          break if c.ord == 0
          body << c.chr
        end
      end
      # Messages should be forever immutable.
      Stomper::Frames::ServerFrame.build(command, headers, body).freeze
    end
  end
end
