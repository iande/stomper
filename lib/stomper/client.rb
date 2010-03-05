module Stomper
  # A high-level representation of a connection to a Stomp message broker.
  # Instances of Client can be shared safely between threads, all mutating
  # methods should be properly synchronized.  Interactions with the stomp
  # message broker through instances of Client are generally simpler than
  # doing so through instances of Connection.  Client instances do not require
  # the use of Stomper::Frames::ClientFrame objects to transmit and receive
  # information, instead relying on specific method calls to do so.
  #
  # === Example Usage
  #   client = Stomper::Client.new("stomp://localhost:61613")
  #   client.start
  #
  #   client.subscribe("/queue/target1") do |msg|
  #     puts "Received Message: #{msg.body}"
  #   end
  #
  #   client.send("/queue/target1", "this is a test")
  #   client.send("/queue/target1", "this persists", { :persistent => true })
  #
  #   client.transaction do |t1|
  #     t1.send("/queue/target1", "this will never be seen")
  #     raise "Forced Exception"
  #   end
  #
  #   client.unsubscribe("/queue/target1")
  #
  #   client.stop
  #   client.close
  #
  class Client
    attr_reader :connection, :subscriptions

    # Creates a new Client instance that will connect to the stomp broker
    # designated by the +uri+ parameter.  Additionally, +options+ may be
    # specified as a hash, and are passed along to the underlying connection.
    # For details on the format of +uri+ and the acceptable +options+, see
    # Stomper::Connection.
    def initialize(uri, options={})
      # At this time we only bother with the BasicConnection.  We will need
      # to write the ReliableConnection class to handle the particulars of reconnecting
      # on a socket error.
      #if options.has_key?(:max_retries) || options.delete(:reliable) { false }
        #@connection = ReliableConnection.new(uri, options)
      #else
        @connection = Connection.new(uri, options)
      #end
      @subscriptions = Subscriptions.new
      @send_lock = Mutex.new
      @receive_lock = Mutex.new
      @run_thread = nil
      @receiving = false
      @receiver_lock = Mutex.new
    end

    # Sends a string message specified by +body+ to the appropriate stomp
    # broker destination given by +destination+.  Additional headers for the
    # message may be specified by the +headers+ hash where the key is the header
    # property and the value is the corresponding property's value.  The
    # keys of +headers+ may be symbols or strings.
    #
    # Examples:
    #
    #   client.send("/topic/whatever", "hello world")
    #
    #   client.send("/queue/some/destination", "hello world", { :persistent => true })
    #
    def send(destination, body, headers={})
      transmit_frame(Stomper::Frames::Send.new(destination, body, headers))
    end

    # Acknowledge to the stomp broker that a given message was received.
    # The +id_or_frame+ parameter may be either the message-id header of
    # the received message, or an actual instance of Stomper::Frames::Message.
    # Additional headers may be specified through the +headers+ hash.
    #
    # Examples:
    #
    #   client.ack(received_message)
    #
    #   client.ack("message-0001-00451-003031")
    #
    def ack(id_or_frame, headers={})
      transmit_frame(Stomper::Frames::Ack.ack_for(id_or_frame, headers))
    end

    # Tells the stomp broker to commit a transaction named by the
    # supplied +transaction_id+ parameter.  When used in conjunction with
    # +begin+, and +abort+, a means for manually handling transactional
    # message passing is provided.
    #
    # See Also: transaction
    def commit(transaction_id)
      transmit_frame(Stomper::Frames::Commit.new(transaction_id))
    end

    # Tells the stomp broker to abort a transaction named by the
    # supplied +transaction_id+ parameter.  When used in conjunction with
    # +begin+, and +commit+, a means for manually handling transactional
    # message passing is provided.
    #
    # See Also: transaction
    def abort(transaction_id)
      transmit_frame(Stomper::Frames::Abort.new(transaction_id))
    end

    # Tells the stomp broker to begin a transaction named by the
    # supplied +transaction_id+ parameter.  When used in conjunction with
    # +commit+, and +abort+, a means for manually handling transactional
    # message passing is provided.
    #
    # See also: transaction
    def begin(transaction_id)
      transmit_frame(Stomper::Frames::Begin.new(transaction_id))
    end

    # Creates a new Stomper::Transaction object and evaluates
    # the supplied +block+ within a transactional context.  If
    # the block executes successfully, the transaction is committed,
    # otherwise it is aborted.  This method is meant to provide a less
    # tedious approach to transactional messaging than the +begin+,
    # +abort+ and +commit+ methods.
    #
    # See also: begin, commit, abort, Stomper::Transaction
    def transaction(transaction_id=nil, &block)
      begin
        Stomper::Transaction.new(self, transaction_id, &block)
      rescue Stomper::TransactionAborted
        nil
      end
      self
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
      @subscriptions << destination
      transmit_frame(destination.to_subscribe)
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
      @subscriptions.remove(destination, sub_id).each do |unsub|
        transmit_frame(unsub.to_unsubscribe)
      end
      self
    end

    # Starts the receiver for a Client instance.  This method
    # must be manually invoked in order to receive frames sent
    # by the stomp broker.  Be aware that a Client object's
    # receiver runs in its own separate thread, and so may
    # incur some performance penalties depending upon which
    # Ruby environment this library is used with.  The receiver
    # thread may be stopped by calling the +stop+ instance method.
    # If the receiver is set to non-blocking (default behavior), the
    # receiving thread will sleep for a number of seconds specified by the
    # :receive_delay option between receive calls.
    #
    # The +opts+ parameter is a hash of options, and can include:
    #
    # [:block] Sets the receiver to either blocking if true (default: false)
    # [:receive_delay] Sets the delay in seconds between receive calls when the receiver is non-blocking (default: 0.2)
    #
    # See also: stop, receiving?
    def start(opts={})
      @connection.connect unless connected?
      do_start = false
      @receiver_lock.synchronize do
        do_start = !receiving?
      end
      if do_start
        blocking = opts.delete(:block) { false }
        sleep_time = opts.delete(:receive_delay) { 0.2 }
        @receiving = true
        @run_thread = Thread.new(blocking) do |block|
          while receiving?
            receive(block)
            sleep(sleep_time) unless block
          end
        end
      end
      self
    end

    # Stops the receiver for a Client instance.  The methodology
    # employed to stop the thread should be safe (it does not
    # make use of Thread.kill)  It is also safe to +start+ and
    # +stop+ the receiver thread multiple times, doing so does not
    # interrupt the connection to the stomp broker under normal
    # circumstances.  In the interest in proper performance, it is
    # recommend that +stop+ be called when a Client instance is
    # no longer needed (assuming the instance's receiver thread was
    # started, of course.)
    #
    # See also: start, receiving?
    def stop
      do_stop = false
      @receiver_lock.synchronize do
        do_stop = receiving?
      end
      if do_stop
        @receiving = false
        @run_thread.join
        @run_thread = nil
      end
      self
    end

    # Returns true if the receiver thread has been started
    # by use of the +start+ command.  Otherwise, returns false.
    #
    # See also: start, stop
    def receiving?
      @receiving
    end

    # Receives the next available frame from the stomp broker, if
    # one is available.  This method is regularly invoked by the
    # receiver thread if it is created by the +start+ method; however,
    # it may also be invoked manually if so desired, allowing one to
    # by-pass the threaded implementation of receiving found in using
    # +start+ and +stop+.  If the received frame is an instance of
    # Stomper::Frames::Message, this method will invoke any subscriptions
    # that are responsible for the message.
    #
    # Note: this method does not block under normal operation, as such
    # +nil+ may be returned if there are no frames available from the
    # stomp broker.
    #
    # See also: Stomper::Subscription
    def receive(block=false)
      msg = @receive_lock.synchronize { @connection.receive(block) }
      @subscriptions.perform(msg) if msg.is_a?(Stomper::Frames::Message)
      msg
    end

    # Toying with an idea, probably a very bad one!
    def each # :nodoc:
      while connected?
        yield receive
      end
    end

    # Returns true if the client is connected, false otherwise.
    def connected?
      @connection.connected?
    end

    # Disconnects from the stomp broker politely by first transmitting
    # a Stomper::Frames::Disconnect frame to the broker.
    def disconnect
      @connection.disconnect
    end

    alias close disconnect

    protected
    # We need to synchronize frame tranmissions to one at a time.
    # My suspicion is that write/puts socket methods are not atomic, so if a message
    # is started then interrupted and a new message is attempted, it will
    # result in either a broken connection or an inconsistent state of our
    # system.
    def transmit_frame(frame)
      @send_lock.synchronize do
        @connection.transmit(frame)
      end
    end
  end
end
