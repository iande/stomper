module Stomper
  class Client
    attr_reader :connection

    # Forms for constructor:
    #   Client.new("stomp://user:pass@host:port") (with variations on the URI)
    #   Client.new("stomp://user:pass@host:port", { :reliable => true, :delay => 5 })
    #   Client.new("stomp://user:pass@host:port", { :max_retries => 5, :delay => 5 })
    #   Client.new({ :host => host, :port => port, :username => user, :password => pass, :secure => false, ... })
    # Allow either a URI followed by a hash of options, or a hash of options specifying
    # all connection parameters.
    # Connection Options:
    # => :host: hostname of server
    # => :port: port of server
    # => :username: username for authentication
    # => :password: password for authentication
    # => :secure: boolean indicating the use of an SSL connection
    #
    # Additional Options
    # => :reliable: boolean indicating if the connection is reliable (default: false)
    # => :delay: delay between connection retries in seconds (default: 5)
    # => :max_retries: number of times to retry connecting when disconnected (default: unlimited)
    #
    # Note that specifying a value for max_retries should implicitly set reliable to true
    def initialize(uri_or_params, options={})
      # At this time we only bother with the BasicConnection.  We will need
      # to write the ReliableConnection class to handle the particulars of reconnecting
      # on a socket error.
      if uri_or_params.is_a?(Hash)
        options = options.merge(uri_or_params)
        @connection = Stomper::BasicConnection.new(options[:host], options[:port],
          options[:user], options[:pass], options[:secure])
      else
        @connection = Stomper::BasicConnection.new(uri_or_params)
      end
      @subscriptions = {}
      @subscription_lock = Mutex.new
      @send_lock = Mutex.new
      @receive_lock = Mutex.new
      @run_thread = nil
      @receiving = false
      @receiver_lock = Mutex.new
    end

    def send(destination, body, headers={})
      transmit_frame(Stomper::Frames::Send.new(destination, body, headers))
    end

    def ack(id_or_frame, headers={})
      transmit_frame(Stomper::Frames::Ack.ack_for(id_or_frame, headers))
    end

    def commit(transaction_id)
      transmit_frame(Stomper::Frames::Commit.new(transaction_id))
    end

    def abort(transaction_id)
      transmit_frame(Stomper::Frames::Abort.new(transaction_id))
    end

    def begin(transaction_id)
      transmit_frame(Stomper::Frames::Begin.new(transaction_id))
    end

    def transaction(transaction_id=nil, &block)
      begin
        Stomper::Transaction.new(self, transaction_id, &block)
      rescue Stomper::TransactionAborted
        nil
      end
      self
    end

    def subscribe(destination, headers={}, &block)
      # If a subscription ID is given, we MUST subscribe to
      # the given destination, even if we're already subscribed
      # with the appropriate "id" header.  We're getting into enough
      # conditional behavior that this should be abstracted out into
      # it's own beast.
      subscribe = headers.has_key?('id') && !headers['id'].nil? && !headers['id'].empty?
      @subscription_lock.synchronize do
        unless @subscriptions.has_key?(destination)
          @subscriptions[destination] = []
          subscribe = true
        end
        @subscriptions[destination] << block
      end
      transmit_frame(Stomper::Frames::Subscribe.new(destination)) if subscribe
      self
    end

    def unsubscribe(destination)
      @subscription_lock.synchronize do
        if @subscriptions.has_key?(destination)
          transmit_frame(Stomper::Frames::Unsubscribe.new(destination))
          @subscriptions[destination].clear
        end
      end
    end

    # The stomp gem we were forked from does this part automatically
    # and I'd rather we didn't.  Perhaps the application developer already
    # has some threads they'd like to use for the purpose of receiving
    # messages.  We can call start automatically within the initializer
    # provided certain options are specified.
    def start
      return self if receiving?
      @receiver_lock.synchronize do
        if @run_thread.nil?
          @receiving = true
          @run_thread = Thread.new do
            while receiving?
              begin
                # if @connection.socket.ready? is no longer needed
                # as we are handling this in the connection layer.
                receive #if @connection.socket.ready?
              rescue => err
                puts "Exception Caught: #{err.to_s}"
                break
              end
              #puts "We are receiving!"
            end
          end
        end
      end
      self
    end

    def stop
      return self unless receiving?
      @receiver_lock.synchronize do
        if receiving?
          @receiving = false
          #With the use of ready? we do not need to force a disconnect
          #@connection.disconnect
          @run_thread.join
          @run_thread = nil
        end
      end
      self
    end

    def receiving?
      @receiving
    end

    def receive
      msg = @receive_lock.synchronize do
        @connection.receive
      end
      if msg.respond_to?(:destination)
        # Could probably make this finer grained, a per-subscription lock
        # but for now, this should do just fine.
        @subscription_lock.synchronize do
          if @subscriptions[msg.destination]
            @subscriptions[msg.destination].each { |sub| sub.call(msg) }
          end
        end
      end
      msg
    end

    # Toying with an idea, probably a very bad one!
    def each
      while connected?
        yield receive
      end
    end

    def connected?
      @connection.connected?
    end

    def disconnect
      @connection.disconnect
    end

    def close
      @connection.disconnect
    end

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
