module Stomper
  module ThreadedReceiver
    def self.extended(base)
      base.instance_eval do
        @receiver_mutex = Mutex.new
      end
    end

    # Starts the threaded receiver on a connection, calling receive
    # on the connection repeatedly in a separate thread until the receiver
    # is stopped or the connection is closed.
    #
    # @return self
    # @see ThreadedReceiver#stop
    # @see Connection#receive
    # @see Connection#connected?
    def start(opts={})
      connect unless connected?
      do_start = false
      @receiver_mutex.synchronize do
        do_start = !started?
      end
      if do_start
        @started = true
        @run_thread = Thread.new() do
          while started? && connected?
            receive
          end
        end
      end
      self
    end

    # Stops the threaded receiver on a connection thereby stopping further
    # calls to receive.
    #
    # @return self
    # @see ThreadedReceiver#start
    # @see Connection#receive
    # @see Connection#connected?
    def stop
      do_stop = false
      @receiver_mutex.synchronize do
        do_stop = started?
      end
      if do_stop
        @started = false
        @run_thread.join
        @run_thread = nil
      end
      self
    end

    private
    def started?
      @started
    end
  end
end
