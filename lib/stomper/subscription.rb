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

    # Let's add a helper method to reduce some of our compound conditionals
    def naive?
      @id.nil? && @selector.nil? && @ack == :auto
    end

    def accepts?(message_frame)
      if message_frame.subscription || !naive?
        @id == message_frame.subscription
      else
        # If this subscription has a selector or a non-auto ack mode, we should
        # not accept the message as the expectations of the call back may not
        # be met!  Instead we are forced to rely on the presence of a subscription
        # header in the message frame!
        message_frame.destination == @destination
      end
    end

    def accepts_messages_from?(destination)
      naive? && destination.to_s == @destination
    end

    def perform(message_frame)
      @call_back.call(message_frame) if accepts?(message_frame)
    end

    def to_subscribe
      headers = { 'destination' => @destination, 'ack' => @ack.to_s }
      headers['id'] = @id unless @id.nil?
      headers['selector'] = @selector unless @selector.nil?
      Stomper::Frames::Subscribe.new(@destination, headers)
    end

    def to_unsubscribe
      headers = { 'destination' => @destination }
      headers['id'] = @id unless @id.nil?
      Stomper::Frames::Unsubscribe.new(@destination, headers)
    end
  end
end
