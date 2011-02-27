# -*- encoding: utf-8 -*-

# Manages subscriptions for a {Stomper::Connection}
class Stomper::SubscriptionManager
  # Creates a new subscription handler for the supplied {Stomper::Connection connection}
  # @param [Stomper::Connection] connection
  def initialize(connection)
    @mon = ::Monitor.new
    @subscribes = {}
    connection.on_message { |m, con| dispatch(m) }
    connection.on_unsubscribe { |u, con| remove(u[:id]) }
    connection.on_connection_closed do |con|
      @subscribes.each { |id, sub| sub.active = false }
    end
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
      @subscribes[s_id] = Subscription.new(subscribe, callback)
    end
  end
  
  # Removes a subscription by ID or destination.
  # @param [String] sub_id ID or destination of the subscription
  # @return [Array<String>] array of subscription IDs matching +sub_id+
  def remove(sub_id)
    @mon.synchronize do
      if @subscribes.key? sub_id
        @subscribes.delete sub_id
        [sub_id]
      else
        @subscribes.values.inject([]) do |ids, sub|
          if sub.destination == sub_id
            @subscribes.delete sub.id
            ids << sub.id
          end
          ids
        end
      end
    end
  end
  
  # Returns all current subscriptions in the form of their SUBSCRIBE frames.
  # @return [Array<Stomper::Frame>]
  def subscribed
    @mon.synchronize { @subscribes.values.select { |s| s.active? } }.map { |s| s.frame }
  end
  
  def inactive_subscriptions
    @mon.synchronize { @subscribes.values.reject { |s| s.active? } }
  end
  
  def remove_inactive_subscription(sub_id)
    @mon.synchronize do
      @subscribes[sub_id] && !@subscribes[sub_id].active? &&
        @subscribes.delete(sub_id)
    end
  end
  
  private
  def dispatch(message)
    s_id = message[:subscription]
    dest = message[:destination]
    if s_id.nil? || s_id.empty?
      @mon.synchronize do
        @subscribes.values.map do |sub|
          (sub.destination == dest) && sub
        end
      end.each { |cb| cb && cb.call(message) }
    else
      cb = @mon.synchronize { @subscribes[s_id] }
      cb && cb.call(message)
    end
  end
  
  class Subscription
    attr_reader :frame, :callback
    attr_accessor :active
    alias :active? :active
    def initialize(fr, cb)
      @frame = fr
      @callback = cb
      @active = true
    end
    def id; @frame[:id]; end
    def destination; @frame[:destination]; end
    def call(m)
      @callback.call(m) if @active
    end
  end
end
