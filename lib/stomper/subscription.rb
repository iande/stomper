module Stomper
  class Subscription
    attr_reader :id, :destination, :ack, :selector
    
    def initialize(destination_or_options, subscription_id=nil, ack=nil, selector=nil, &block)
      if destination_or_options.is_a?(Hash)
        destination = destination_or_options[:destination]
        subscription_id ||= destination_or_options[:id]
        ack ||= destination_or_options[:ack]
        selector ||= destination_or_options[:selector]
      else
        destination = destination_or_options.to_s
      end
      @id = subscription_id
      @destination = destination
      @ack = (ack || :auto).to_sym
      @selector = selector
      @call_back = block
      unless @ack == :auto && (@selector.nil? || @selector.empty?)
        @id ||= "sub-#{Time.now.to_f}"
      end
    end


    # Do we want to support wild-card subscriptions?
    # They aren't part of the stomp-spec proper, but they are
    # supported by ActiveMQ.  For now, we will say no.
    # We MUST support subscription-id matching, as that is a specific
    # part of the stomp spec, and an ID match should take precedence
    # over all other matching.  Incidentally, this solves the wildcard
    # problem.  If a wild-card subscription has an explicit ID specified,
    # matches? does its thing without further work on our part.
    #
    # Here's the issue we're going to run in to:
    # every SUBSCRIBE frame sent on the connection results in a new
    # consumer for the broker.  If no subscription id is specified, the
    # client code will still receive all the messages, but there's no way
    # of knowing which subscription it was meant for.  Normally, this wouldn't
    # be an issue, but when you factor in things like selectors, wild-card destinations,
    # and varying ack modes, distinguishing the subscription is VERY important.
    #
    # Let's talk about expected behaviors in our spec files!
    def matches?(message_frame)
      if message_frame.subscription || @id
        @id == message_frame.subscription
      else
        # If this subscription has a selector or a non-auto ack mode, we should
        # not accept the message as the expectations of the call back may not
        # be met!  Instead we are forced to rely on the presence of a subscription
        # header in the message frame!
        @selector.nil? && @ack == :auto && (message_frame.destination == @destination)
      end
    end

    def perform(message_frame)
      @call_back.call(message_frame) if matches?(message_frame)
    end

    def to_subscribe
      headers = { 'destination' => @destination, 'ack' => @ack.to_s }
      headers['id'] = @id unless @id.nil?
      headers['selector'] = @selector unless @selector.nil?
      Stomper::Frames::Subscribe.new(@destination, headers)
    end
  end
end
