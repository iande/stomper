module Stomper
  class ReceiptHandlers
    include Enumerable

    def initialize
      @recps = []
      @recp_lock = Mutex.new
    end

    def <<(r_hand)
      add(r_hand)
    end

    def add(r_hand)
      @recp_lock.synchronize { @recps << r_hand }
    end

    def each(&block)
      @recp_lock.synchronize { @recps.each(&block) }
    end

    def perform(receipt)
      @recp_lock.synchronize do
        @recps.reject! { |m| m.perform(receipt) }
      end
    end
  end
end
