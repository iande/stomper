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
      @id ||= "sub-#{Time.now.to_f}" unless naive?
    end

    # Let's add a helper method to reduce some of our compound conditionals
    def naive?
      @id.nil? && @selector.nil? && @ack == :auto
    end

    def accepts?(message_frame)
      receives_for?(message_frame.destination, message_frame.subscription)
    end

    def receives_for?(dest, subid=nil)
      if naive? && subid.nil?
        @destination == dest
      else
        @id == subid
      end
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
