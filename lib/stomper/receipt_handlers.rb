module Stomper
  class ReceiptHandlers
    def initialize
      @recps = {}
      @recp_lock = Mutex.new
    end

    def add(receipt_id, callback)
      @recp_lock.synchronize { @recps[receipt_id] = callback }
    end
    
    def size
      @recps.size
    end

    def perform(receipt)
      @recp_lock.synchronize do
        callback = @recps.delete(receipt.for)
        callback.call(receipt) if callback
      end
    end
  end
end
