module Stomper
  module ThreadedReceiver
    def self.extended(base)
      base.instance_eval do
        @receiver_mutex = Mutex.new
      end
    end

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
