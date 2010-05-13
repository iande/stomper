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
    # designated by the +uri+ parameter.
    # For details on the format of +uri+, see Stomper::Connection.
    def initialize(uri)
      @connection = Connection.new(uri)
      @subscriptions = Subscriptions.new
      @send_lock = Mutex.new
      @receive_lock = Mutex.new
      @run_thread = nil
      @receiving = false
      @receiver_lock = Mutex.new
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
          while receiving? && connected?
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

    # Returns true if the client is connected, false otherwise.
    def connected?
      @connection.connected?
    end

    # Establishes a socket connection to the stomp broker and transmits
    # the initial "CONNECT" frame requred per the Stomp protocol.
    def connect
      @connection.connect
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

    private
    # Toying with an idea, probably a very bad one!
    def each # :nodoc:
      while connected?
        yield receive
      end
    end
  end
end
