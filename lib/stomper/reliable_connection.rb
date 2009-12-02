module Stomper
  class RetriesExceededError < RuntimeError; end

  class ReliableConnection < Stomper::BasicConnection
    attr_accessor :reconnect_delay, :max_retries
    
    def initialize(uri_or_connection, opts = {})
      @connection_lock = Mutex.new
      @attempts = 0
      @reconnect_delay = opts.delete(:delay) || 5
      @max_retries = opts.delete(:max_retries) || 0
      super(uri_or_connection, opts.merge(:connect_now => false))
      connect unless connected?
    end
    
    def connect
      begin
        super
      rescue Errno::ECONNREFUSED, IOError, SocketError
        @reconnect = true
        reconnect
      end
    end

    def transmit(frame)
      begin
        super
      rescue IOError
        @reconnect = true
        reconnect
      end
    end

    def receive(blocking=false)
      begin
        super
      rescue IOError
        @reconnect = true
        reconnect
        nil
      end
    end

    def disconnect
      super
      @closed = true
    end

    def close
      super
      @closed = true
    end

    private
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
