module Stomper
  class Client
    attr_reader :connection, :subscriptions

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
      unless destination.is_a?(Subscription)
        destination = Subscription.new(headers.merge(:destination => destination), &block)
      end
      @subscriptions << destination
      transmit_frame(destination.to_subscribe)
      self
    end

    def unsubscribe(destination, sub_id=nil)
      @subscriptions.remove(destination, sub_id).each do |unsub|
        transmit_frame(unsub.to_unsubscribe)
      end
      self
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
                receive
              rescue => err
                puts "Exception Caught: #{err.to_s}"
                break
              end
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
      msg = @receive_lock.synchronize { @connection.receive }
      @subscriptions.perform(msg) if msg.is_a?(Stomper::Frames::Message)
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
