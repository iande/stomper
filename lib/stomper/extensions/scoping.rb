# -*- encoding: utf-8 -*-

# Mixin that provides scoping of user generated frames.
module Stomper::Extensions::Scoping
  # Creates a new {Stomper::Extensions::Scoping::TransactionScope} to perform
  # a transaction. If a block is provided, all SEND, ACK, NACK, COMMIT and
  # ABORT frames generated within the block are bound to the same transaction.
  # Further, if an exception is raised within the block, the transaction is
  # rolled back through an ABORT frame, otherwise it is automatically committed
  # through a COMMIT frame. If a block is not provided, the transaction must
  # be manually aborted or committed through the returned
  # {Stomper::Extensions::Scoping::TransactionScope} object.
  # @param [String,nil] tx_id the ID of the transaction, auto-generated if not
  #   provided.
  # @yield [tx] block is evaluated as a transaction
  # @yieldparam [Stomper::Extensions::Scoping::TransactionScope] tx
  # @return [Stomper::Extensions::Scoping::TransactionScope]
  # @example Gonna need an example or two
  def with_transaction(tx_id=nil, headers={}, &block)
    create_scope(::Stomper::Extensions::Scoping::TransactionScope, headers, block)
  end

  # Creates a new {Stomper::Extensions::Scoping::ReceiptScope} using
  # a supplied block as the receipt handler. If no block is provided, no
  # receipt handler is created; however, all frames generated through this
  # {Stomper::Extensions::Scoping::ReceiptScope} will still request a RECEIPT
  # from the broker.
  # @yield [receipt] callback invoked upon receiving the RECEIPT frame
  # @yieldparam [Stomper::Frame] the received RECEIPT frame
  # @return [Stomper::Extensions::Scoping::ReceiptScope]
  # @example Gonna need an example or two
  # @see Stomper::Extensions::Events#on_receipt}
  def with_receipt(headers={}, &block)
    create_scope(::Stomper::Extensions::Scoping::ReceiptScope, headers, block)
  end
  
  # Creates a new {Stomper::Extensions::Scoping::HeaderScope} from the
  # supplied hash of headers. If a block is provided, it will be invoked with
  # with this {Stomper::Extensions::Scoping::HeaderScope} as its only parameter.
  # @yield [header_scope] block is evaluated applying the specified headers to
  #   all frames generated within the block.
  # @yieldparam [Stomper::Extensions::Scoping::HeaderScope] header_scope
  # @return [Stomper::Extensions::Scoping::HeaderScope]
  # @example Gonna need an example or two
  def with_headers(headers, &block)
    create_scope(::Stomper::Extensions::Scoping::HeaderScope, headers, block)
  end
  
  def create_scope(klass, headers, callback)
    klass.new(self, headers).tap do |scoped|
      scoped.apply_to(callback)
    end
  end
  private :create_scope
  
  class HeaderScope
    include ::Stomper::Extensions::Common

    attr_reader :connection
    attr_reader :headers
    
    def initialize(parent, headers)
      @headers = ::Stomper::Support.keys_to_sym(headers)
      if parent.is_a?(::Stomper::Connection)
        @connection = parent
      else
        @connection = parent.connection
        @headers = parent.headers.merge(@headers)
      end
      # Extend the protocol version specific modules used in the connection
      ::Stomper::Extensions::Protocols::EXTEND_BY_VERSION[@connection.version].each do |mod|
        extend mod
      end
    end
    
    def apply_to(callback)
      callback.call(self) if callback
    end
    
    def transmit(frame)
      frame.headers.reverse_merge!(@headers)
      @connection.transmit frame
    end
  end
  
  # Automatically generates "receipt" headers, if none are present and
  # applys a supplied callback to every receipt received for frames generated
  # through it. As instances of this class rely on event callbacks attached
  # to the underlying {Stomper::Connection connection}, it is entirely possible
  # for those events to be triggered on +Thread+ other than main. It is for
  # this reason that synchronization is used to ensure the integrity of
  # the internal list of receipt IDs that have not yet been processed through
  # the callback.
  class ReceiptScope < HeaderScope
    FRAME_COMMANDS = %w(SEND SUBSCRIBE UNSUBSCRIBE
      BEGIN COMMIT ABORT ACK NACK DISCONNECT)
    
    def initialize(parent, headers)
      super
      @receipt_ids = []
      @receipt_handler = nil
      @handler_installed = false
      @receipt_mutex = ::Mutex.new
    end
    
    def apply_to(callback)
      @receipt_handler = callback
    end
    
    def transmit(frame)
      if check_receipt_handler
        r_id = frame[:receipt]
        r_id = ::Stomper::Support.next_serial if r_id.nil? || r_id.empty?
        @receipt_mutex.synchronize do
          @receipt_ids << r_id
        end
        frame[:receipt] = r_id
      end
      super(frame)
    end
    
    private
    def check_receipt_handler
      if @receipt_handler && !@handler_installed
        @connection.on_receipt do |receipt|
          r_id = receipt[:'receipt-id']
          @receipt_mutex.synchronize do
            if @receipt_ids.include?(r_id)
              @receipt_handler.call(receipt)
              @receipt_ids.delete(r_id)
            end
          end
        end
        @handler_installed = true
      end
      @handler_installed
    end
  end
  
  class TransactionScope < HeaderScope
    FRAME_COMMANDS = %w(SEND BEGIN COMMIT ABORT ACK NACK)
    attr_reader :transaction
    
    def initialize(parent, headers)
      super
      @headers[:transaction] ||= ::Stomper::Support.next_serial
      @transaction = self.headers[:transaction]
      @transaction_state = :pending
    end
    
    def begin_with_transaction(headers={})
      if transaction_pending?
        @transaction_state = :starting
      else
        raise ::Stomper::Errors::TransactionStartedError unless transaction_pending?
      end
      begin_without_transaction(@transaction, headers).tap do |f|
        @transaction_state = :started
      end
    end
    alias :begin_without_transaction :begin
    alias :begin :begin_with_transaction
    
    def abort_with_transaction(headers={})
      abort_without_transaction(@transaction, headers).tap do |f|
        @transaction_state = :aborted
      end
    end
    alias :abort_without_transaction :abort
    alias :abort :abort_with_transaction
    
    def commit_with_transaction(headers={})
      commit_without_transaction(@transaction, headers).tap do |f|
        @transaction_state = :committed
      end
    end
    alias :commit_without_transaction :commit
    alias :commit :commit_with_transaction
    
    def transmit(frame)
      self.begin if transaction_pending?
      if FRAME_COMMANDS.include? frame.command
        if frame.command != 'BEGIN' && transaction_finalized?
          raise ::Stomper::Errors::TransactionFinalizedError
        end
        super(frame)
      else
        @connection.transmit frame
      end
    end
    
    def apply_to(callback)
      begin
        super
        self.commit if transaction_started?
      rescue Exception => err
        self.abort if transaction_started?
        raise err
      end
    end
    
    def transaction_pending?; @transaction_state == :pending; end
    def transaction_started?; @transaction_state == :started; end
    def transaction_committed?; @transaction_state == :committed; end
    def transaction_aborted?; @transaction_state == :aborted; end
    def transaction_finalized?; transaction_aborted? || transaction_committed?; end
  end
end
