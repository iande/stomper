# -*- encoding: utf-8 -*-

# Manages subscriptions for a {Stomper::Connection}
class Stomper::SubscriptionManager
  # Creates a new subscription handler for the supplied {Stomper::Connection connection}
  # @param [Stomper::Connection] connection
  def initialize(connection)
    @mon = ::Monitor.new
    @callbacks = {}
    @dests_to_ids = {}
    connection.on_message { |m| dispatch(m) }
    connection.on_unsubscribe { |u| remove(u) }
  end
  
  # Adds a callback handler for a MESSAGE frame that is sent via the subscription
  # associated with the supplied SUBSCRIBE frame.
  # @param [Stomper::Frame] subscribe SUBSCRIBE frame for the subscription
  # @param [Proc] callback Proc to invoke when a matching MESSAGE frame is
  #   received from the broker.
  # @return [self]
  def add(subscribe, callback)
    s_id = subscribe[:id]
    dest = subscribe[:destination]
    @mon.synchronize do
      @callbacks[s_id] = callback
      @dests_to_ids[dest] ||= []
      @dests_to_ids[dest] << s_id
    end
  end
  
  # Returns true if the subscription ID is registered
  # @param [String] id
  # @return [true,false]
  def subscribed_id?(id)
    @mon.synchronize { @callbacks.key? id }
  end
  
  # Returns true if the subscription destination is registered
  # @param [String] destination
  # @return [true,false]
  def subscribed_destination?(destination)
    @mon.synchronize { @dests_to_ids.key? destination }
  end
  
  # Returns an array of subscription IDs that correspond to
  # the given subscription destination. If the destination is unknown,
  # returns +nil+.
  # @param [String] destination
  # @return [Array<String>, nil]
  def ids_for_destination(destination)
    @mon.synchronize { @dests_to_ids[destination] && @dests_to_ids[destination].dup }
  end
  
  private
  def remove(unsub)
    s_id = unsub[:id]
    @mon.synchronize do
      @dests_to_ids.each do |dest, ids|
        ids.delete s_id
        @dests_to_ids.delete dest if ids.empty?
      end
      @callbacks.delete(s_id)
    end
  end
  
  def dispatch(message)
    s_id = message[:subscription]
    dest = message[:destination]
    if s_id.nil? || s_id.empty?
      cbs = @mon.synchronize do
        @dests_to_ids[dest] && @dests_to_ids[dest].map { |id| @callbacks[id] }
      end
      cbs && cbs.each { |cb| cb.call(message) }
    else
      cb = @mon.synchronize { @callbacks[s_id] }
      cb && cb.call(message)
    end
  end
end
