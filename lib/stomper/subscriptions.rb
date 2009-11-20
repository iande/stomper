module Stomper
  class Subscriptions
    include Enumerable
    
    def initialize
      @subs = []
      @sub_lock = Mutex.new
    end

    def <<(sub)
      raise ArgumentError, "appended object must be a subscription" unless sub.is_a?(Subscription)
      @sub_lock.synchronize { @subs << sub }
    end

    def add(sub)
      self << sub
    end

    def size
      @sub_lock.synchronize { @subs.size }
    end

    def first
      @sub_lock.synchronize { @subs.first }
    end

    def last
      @sub_lock.synchronize { @subs.last }
    end

    def each(&block)
      @sub_lock.synchronize { @subs.each(&block) }
    end

    def perform(message)
      @sub_lock.synchronize { @subs.each { |sub| sub.perform(message) } }
    end
  end
end
