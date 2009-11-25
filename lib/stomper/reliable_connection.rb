module Stomper
  class RetriesExceededError < RuntimeError; end

  class ReliableConnection
    include Stomper::Decogator
    attr_accessor :reconnect_delay, :max_retries

    delegates :connect, :disconnect, :close, :transmit, :receive, :connected?, :to => :'@connection'
    around :connect, :call => :guard_connect
    around :transmit, :receive, :call => :guard_io
    after :disconnect, :close, :call => :explicitly_disconnect
    
    def initialize(uri_or_connection, opts = {})
      @connection_lock = Mutex.new
      @attempts = 0
      @reconnect_delay = opts.delete(:delay) || 5
      @max_retries = opts.delete(:max_retries) || 0

      if uri_or_connection.is_a?(BasicConnection)
        @connection = uri_or_connection
      else
        @connection = BasicConnection.new(uri_or_connection, opts.merge(:connect_now => false))
      end
      connect unless connected?
    end

    private
    def guard_io
      begin
        yield
      rescue IOError
        @reconnect = true
        reconnect
      end
    end

    def guard_connect
      begin
        yield
      rescue Errno::ECONNREFUSED, IOError, SocketError
        @reconnect = true
        reconnect
      end
    end

    def explicitly_disconnect
      @closed = true
    end

    def reconnect
      return if @closed || !@reconnect
      do_connect = false
      @connection_lock.synchronize do
        do_connect, @reconnect = (!@closed && @reconnect), false
      end
      if do_connect
        if @max_retries == 0 || @attempts < @max_retries
          sleep(@reconnect_delay) if @reconnect_delay > 0
          connect
        else
          raise RetriesExceededError, "maximum retries exceeded"
        end
      end
    end
  end
end
