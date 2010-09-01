module Stomper
  module ThreadedReceiver
    def after_initialize
      @threaded_receiver_locks = {
        :receiver => Mutex.new,
        :receive => Mutex.new,
        :transmit => Mutex.new
      }
    end

    def start(opts={})
      connect unless connected?
      do_start = false
      synchronize_on_mutex(:receiver) do
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
      synchronize_on_mutex(:receiver) do
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

    def synchronize_on_mutex(mutex_sym, &block)
      @threaded_receiver_locks[mutex_sym].lock(&block)
    end
  end
end
