module Stomper
  class Subscriptions
    include Enumerable
    
    def initialize
      @subs = []
      @sub_lock = Mutex.new
    end

    def <<(sub)
      add(sub)
    end

    def add(sub)
      raise ArgumentError, "appended object must be a subscription" unless sub.is_a?(Subscription)
      @sub_lock.synchronize { @subs << sub }
    end

    def remove(dest, subid=nil)
      if dest.is_a?(Hash)
        subid = dest[:id]
        dest = dest[:destination]
      elsif dest.is_a?(Subscription)
        subid = dest.id
        dest = dest.destination
      end
      _remove(dest, subid)
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

    private
    def _remove(dest, subid)
      @sub_lock.synchronize do
        to_remove, @subs = @subs.partition { |s| s.receives_for?(dest,subid) }
        to_remove
      end
    end
  end
end
