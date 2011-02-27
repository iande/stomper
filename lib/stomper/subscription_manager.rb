# -*- encoding: utf-8 -*-

# Manages subscriptions for a {Stomper::Connection}
class Stomper::SubscriptionManager
  # Creates a new subscription handler for the supplied {Stomper::Connection connection}
  # @param [Stomper::Connection] connection
  def initialize(connection)
    @mon = ::Monitor.new
    @subscriptions = {}
    connection.on_message { |m, con| dispatch(m) }
    connection.on_unsubscribe { |u, con| remove(u[:id]) }
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
      @subscriptions[s_id] = Subscription.new(subscribe, callback)
    end
  end
  
  # Removes a subscription by ID or destination.
  # @param [String] sub_id ID or destination of the subscription
  # @return [Array<String>] array of subscription IDs matching +sub_id+
  def remove(sub_id)
    @mon.synchronize do
      if @subscriptions.key? sub_id
        @subscriptions.delete sub_id
        [sub_id]
      else
        @subscriptions.values.inject([]) do |ids, sub|
          if sub.destination == sub_id
            @subscriptions.delete sub.id
            ids << sub.id
          end
          ids
        end
      end
    end
  end
  
  # Returns all current subscriptions.
  # @return [Array<Stomper::SubscriptionManager::Subscription>]
  def subscriptions
    @mon.synchronize { @subscriptions.values }
  end
  
  # Remove all subscriptions. This method does not send UNSUBSCRIBE frames
  # to the broker.
  def clear
    @mon.synchronize { @subscriptions.clear }
  end
  
  private
  def dispatch(message)
    s_id = message[:subscription]
    dest = message[:destination]
    if s_id.nil? || s_id.empty?
      @mon.synchronize do
        @subscriptions.values.map do |sub|
          (sub.destination == dest) && sub
        end
      end.each { |cb| cb && cb.call(message) }
    else
      cb = @mon.synchronize { @subscriptions[s_id] }
      cb && cb.call(message)
    end
  end
  
  class Subscription
    attr_reader :frame, :callback
    def initialize(fr, cb)
      @frame = fr
      @callback = cb
    end
    def id; @frame[:id]; end
    def destination; @frame[:destination]; end
    def call(m); @callback.call(m); end
  end
end
