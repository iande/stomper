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
        #blocking = opts.delete(:blocking) { true }
        #sleep_time = opts.delete(:receive_delay) { 0.2 }
        @started = true
        @run_thread = Thread.new() do
          while started? && connected?
            receive
            #receive(block)
            #sleep(sleep_time) unless block
          end
        end
      end
      self
    end

    def stop
      do_stop = false
      @receiver_mutex.synchronize do
        do_stop = receiving?
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
