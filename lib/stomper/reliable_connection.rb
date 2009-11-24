module Stomper
  class ReliableConnection
    attr_accessor :reconnect_delay

    def initialize(uri_or_connection, opts = {})
      @connection_lock = Mutex.new
      @reconnect_delay = 0
      if uri_or_connection.is_a?(BasicConnection)
        @connection = uri_or_connection
        @reconnect = !@connection.connected?
      else
        @connection = BasicConnection.new(uri_or_connection, opts.merge(:connect_now => false))
        begin
          @connection.connect
          @reconnect = false
        rescue
          @reconnect = true
        end
      end
    end
    
    def before_close
      explicitly_disconnected
    end
    
    def before_disconnect
      explicitly_disconnected
    end

    def around_connect
      begin
        yield
      rescue IOError
        @reconnect = true
      end
    end

    def around_transmit
      begin
        yield
      rescue IOError
        @reconnect = true
      end
    end

    def around_receive
      begin
        yield
      rescue IOError
        @reconnect = true
      end
    end

    def after_connect
      ensure_connection
    end

    def after_transmit
      ensure_connection
    end

    def after_receive
      ensure_connection
    end

    def method_missing(meth, *args, &block)
      if @connection.respond_to?(meth)
        if respond_to?("before_#{meth}")
          self.send("before_#{meth}")
        end
        res = nil
        if respond_to?("around_#{meth}")
          self.send("around_#{meth}") do
            res = @connection.send(meth, *args, &block)
          end
        else
          res = @connection.send(meth, *args, &block)
        end
        if respond_to?("after_#{meth}")
          self.send("after_#{meth}")
        end
        res
      else
        raise NoMethodError, "no such method #{meth}"
      end
    end

    def respond_to?(meth)
      super || @connection.respond_to?(meth)
    end

    private
    def ensure_connection
      reconnect if reconnect?
    end

    def reconnect?
      @reconnect
    end

    def reconnect
      return unless reconnect?
      do_connect = false
      @connection_lock.synchronize do
        do_connect, @reconnect = @reconnect, false
      end
      if do_connect
        begin
          sleep(@reconnect_delay) if @reconnect_delay > 0
          #@connection.connect
          connect
        rescue
          @reconnect = true
        end
      end
    end

    def explicitly_disconnected
      @reconnect = false
    end
  end
end
