module Stomper
  # A representation of a subscription to a stomp broker destination.  The
  # attributes +id+, +destination+, +ack+ and +selector+ have the same
  # semantic meaning as the headers of a Stomp "SUBSCRIBE" frame with the same
  # name.
  class Subscription
    attr_reader :id, :destination, :ack, :selector

    # Creates a new Subscription instance from the given parameters.
    # The +destination_or_options+ parameter can either be a string
    # specification of the destination, such as "/queue/target", or a hash
    # corresponding to the headers of a "SUBSCRIBE" frame
    # (eg: { :destination => "/queue/target", :id => "sub-001", ... })
    #
    # The optional +subscription_id+ parameter is a string corresponding
    # to the name of this subscription.  If this parameter is specified, it
    # should be unique within the context of a given Stomper::Client, otherwise
    # the behavior of the Stomper::Client#unsubscribe method may have unintended
    # consequences.
    #
    # The optional +ack+ parameter specifies the mode that a client
    # will use to acknowledge received messages and may be either :client or :auto.
    # The default, :auto, does not require the client to notify the broker when
    # it has received a message; however, setting +ack+ to :client will require
    # each message received by this subscription to be acknowledged through the
    # use of Stomper::Client#ack in order to ensure proper interaction between
    # client and broker.
    #
    # The +selector+ parameter (again, optional) sets a SQL 92 selector for
    # this subscription with the stomp broker as per the Stomp Protocol specification.
    # Support of this functionality is entirely the responsibility of the broker,
    # there is no client side filtering being done on incoming messages.
    #
    # When a message is "received" by an instance of Subscription, the supplied
    # +block+ is inovked with the received message sent as a parameter.
    #
    # If no +subscription_id+ is specified, either explicitly or through a
    # hash key of 'id' in +destination_or_options+, one may be automatically
    # generated of the form "sub-#{Time.now.to_f}".  The automatic generation
    # of a subscription id occurs if and only if naive? returns false.
    #
    # While direct creation of Subscription instances is possible, the preferred
    # method is for them to be constructed by a Stomper::Client through the use
    # of the Stomper::Client#subscribe method.
    #
    # See also: naive?, Stomper::Client#subscribe, Stomper::Client#unsubscribe,
    # Stomper::Client#ack
    #
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

    # Returns true if this subscription has no explicitly specified id,
    # has no selector specified, and acknowledges messages through the :auto
    # mode.
    def naive?
      @id.nil? && @selector.nil? && @ack == :auto
    end

    # Returns true if this subscription is responsible for a Stomper::Client
    # instance receiving +message_frame+.
    #
    # See also: receives_for?, perform
    def accepts?(message_frame)
      receives_for?(message_frame.destination, message_frame.subscription)
    end

    # Returns true if this subscription is responsible for receiving
    # messages for the given destination or subscription id, specified
    # by +dest+ and +subid+ respectively.
    #
    # Note: if +subid+ is non-nil or this subscription is not naive?,
    # then this method returns true if and only if the supplied +subid+ is
    # equal to the +id+ of this subscription.  Otherwise, the return value
    # depends only upon the equality of +dest+ and this subscriptions +destination+
    # attribute.
    #
    # See also: naive?
    def receives_for?(dest, subid=nil)
      if naive? && subid.nil?
        @destination == dest
      else
        @id == subid
      end
    end

    # Invokes the block associated with this subscription if
    # this subscription accepts the supplied +message_frame+.
    #
    # See also: accepts?
    def perform(message_frame)
      @call_back.call(message_frame) if accepts?(message_frame)
    end

    # Converts this representation of a subscription into a
    # Stomper::Frames::Subscribe client frame that can be transmitted
    # to a stomp broker through a Stomper::Connection instance.
    def to_subscribe
      headers = { :destination => @destination, :ack => @ack.to_s }
      headers[:id] = @id unless @id.nil?
      headers[:selector] = @selector unless @selector.nil?
      Stomper::Frames::Subscribe.new(@destination, headers)
    end

    # Converts this representation of a subscription into a
    # Stomper::Frames::Unsubscribe client frame that can be transmitted
    # to a stomp broker through a Stomper::Connection instance.
    def to_unsubscribe
      headers = { :destination => @destination }
      headers[:id] = @id unless @id.nil?
      Stomper::Frames::Unsubscribe.new(@destination, headers)
    end
  end
end
