module Stomper
  # A Subscription collection class used internally by Stomper::Client to store
  # its subscriptions.  Instances of this class utilize synchronization making
  # it safe to use in a multi-threaded context.
  class Subscriptions
    include Enumerable

    # Creates a new Subscriptions container.
    def initialize
      @subs = []
      @sub_lock = Mutex.new
    end

    # Adds the supplied subscription, +sub+, to the collection.
    def <<(sub)
      add(sub)
    end

    # Adds the supplied subscription, +sub+, to the collection.
    def add(sub)
      raise ArgumentError, "appended object must be a subscription" unless sub.is_a?(Subscription)
      @sub_lock.synchronize { @subs << sub }
    end

    # Removes all Subscription objects from the collection that match
    # the supplied destination, +dest+, and subscription id, +subid+.
    # If +dest+ is a hash, the value referenced by the :destination key
    # will be used as the destination, and +subid+ will be set to the value
    # referenced by :id, unless it is explicitly set beforehand.  If +dest+ is
    # an instance of Subscription, the +destination+ attribute will be used
    # as the destination, and +subid+ will be set to the +id+ attribute, unless
    # explicitly set beforehand.  The Subscription objects removed are all of
    # those, and only those, for which the Stomper::Subscription#receives_for?
    # method returns true given the destination and/or subscription id.
    #
    # This method returns an array of all the Subscription objects that were
    # removed, or an empty array if none were removed.
    #
    # See also: Stomper::Subscription#receives_for?, Stomper::Client#unsubscribe
    def remove(dest, subid=nil)
      if dest.is_a?(Hash)
        subid ||= dest[:id]
        dest = dest[:destination]
      elsif dest.is_a?(Subscription)
        subid ||= dest.id
        dest = dest.destination
      end
      _remove(dest, subid)
    end

    # Returns the number of Subscription objects within the container through
    # the use of synchronization.
    def size
      @sub_lock.synchronize { @subs.size }
    end

    # Returns the first Subscription object within the container through
    # the use of synchronization.
    def first
      @sub_lock.synchronize { @subs.first }
    end

    # Returns the last Subscription object within the container through
    # the use of synchronization.
    def last
      @sub_lock.synchronize { @subs.last }
    end

    # Evaluates the supplied +block+ for each Subscription object
    # within the container, or yields an Enumerator for the collection
    # if no +block+ is given.  As this method is synchronized, it is
    # entirely possible to enter into a dead-lock if the supplied block
    # in turn calls any other synchronized method of the container.
    # [This could be remedied by creating a new array with
    # the same Subscription objects currently contained, and performing
    # the +each+ call on the new array. Give this some thought.]
    def each(&block)
      @sub_lock.synchronize { @subs.each(&block) }
    end

    # Passes the supplied +message+ to all Subscription objects within the
    # collection through their Stomper::Subscription#perform method.
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
