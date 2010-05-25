module Stomper
  module SubscriberInterface
    def self.included(base)
      if base.method_defined?(:receive)
        base.instance_eval do
          alias_method :receive_without_message_dispatch, :receive
          alias_method :receive, :receive_with_message_dispatch
        end
      end
    end

    # Receives a frame and dispatches it to the known subscriptions, if the
    # received frame is a MESSAGE frame.
    def receive_with_message_dispatch
      frame = receive_without_message_dispatch
      subscriptions.perform(frame) if frame.is_a?(Stomper::Frames::Message)
      frame
    end

    # Subscribes to the specified +destination+, passing along
    # the optional +headers+ inside the subscription frame.  When a message
    # is received for this subscription, the supplied +block+ is
    # called with the received message as its argument.
    #
    # Examples:
    #
    #   client.subscribe("/queue/test")  { |msg| puts "Got message: #{msg.body}" }
    #
    #   client.subscribe("/queue/test", :ack => 'client', 'id' => 'subscription-001') do |msg|
    #     puts "Got message: #{msg.body}"
    #   end
    #
    #   client.subscribe("/queue/test", :selector => 'cost > 5') do |msg|
    #     puts "Got message: #{msg.body}"
    #   end
    #
    # See also: unsubscribe, Stomper::Subscription
    def subscribe(destination, headers={}, &block)
      unless destination.is_a?(Subscription)
        destination = Subscription.new(headers.merge(:destination => destination), &block)
      end
      self.subscriptions << destination
      transmit(destination.to_subscribe)
      self
    end

    # Unsubscribes from the specified +destination+.  The +destination+
    # parameter may be either a string, such as "/queue/test", or Stomper::Subscription
    # object.  If the optional +sub_id+ is supplied, the client will unsubscribe
    # from the subscription with an id matching +sub_id+, regardless if the
    # +destination+ parameter matches that of the registered subscription.  For
    # this reason, it is vital that subscription ids, if manually specified, be
    # unique.
    #
    # Examples:
    #
    #   client.unsubscribe("/queue/test")
    #   # unsubscribes from all "naive" subscriptions for "/queue/test"
    #
    #   client.unsubscribe("/queue/does/not/matter", "sub-0013012031")
    #   # unsubscribes from all subscriptions with id of "sub-0013012031"
    #
    #   client.unsubscribe(some_subscription)
    #
    # See also: subscribe, Stomper::Subscription
    def unsubscribe(destination, sub_id=nil)
      self.subscriptions.remove(destination, sub_id).each do |unsub|
        transmit(unsub.to_unsubscribe)
      end
      self
    end

    def subscriptions
      @subscriptions ||= ::Stomper::Subscriptions.new
    end
  end
end
