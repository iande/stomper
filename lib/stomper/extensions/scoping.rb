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
  
  # A "connection scope" that provides much of the same interface as 
  # {Stomper::Connection}, but automatically applies header name/value pairs
  # to all frames generated on the scope.
  class HeaderScope
    include ::Stomper::Extensions::Common

    # The underlying {Stomper::Connection connection} to transmit frames through.
    # @return [Stomper::Connection]
    attr_reader :connection
    # The headers to apply to all frames generated on this scope.
    # @return [{Symbol => String}]
    attr_reader :headers
    
    # Creates a new {HeaderScope}.  The supplied +headers+ hash will have
    # all of its keys converted to symbols and its values converted to strings,
    # so the key/value pairs must support this transformation (through +to_sym+
    # and +to_s+, respectively.)
    # @overload initialize(connection, headers)
    #   Creates a new scope, using the supplied connection to deliver
    #   frames. Header name/value pairs of this instance are applied to
    #   frames generated on this instance.
    #   @param [Stomper::Connection] connection
    #   @param [{Object => String}] headers
    # @overload initialize(scope, headers)
    #   Creates a new 'child scope' of the supplied 'parent scope'. Header
    #   name/value pairs of the parent and of this instance are applied to
    #   frames generated on this instance, with the child headers taking
    #   precendence over the parent's.
    #   @param [HeaderScope] parent
    #   @param [{Object => String}] headers
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
    
    # Applies this scope to a block.
    def apply_to(callback)
      callback.call(self) if callback
    end
    
    # Transmits a frame, applying the set headers. After merging its headers
    # into the frame, the frame is passed to the underlying connection for
    # transmission.
    # @param [Stomper::Frame] frame
    def transmit(frame)
      frame.headers.reverse_merge!(@headers)
      @connection.transmit frame
    end
  end
  
  # Automatically generates "receipt" headers, if none are present and
  # applies a supplied callback to every receipt received for frames generated
  # through it. As instances of this class rely on event callbacks attached
  # to the underlying {Stomper::Connection connection}, it is entirely possible
  # for those events to be triggered on +Thread+ other than main. It is for
  # this reason that synchronization is used to ensure the integrity of
  # the internal list of receipt IDs that have not yet been processed through
  # the callback.
  class ReceiptScope < HeaderScope
    # A list of frames that support being receipted.
    # @return [Array<String>]
    FRAME_COMMANDS = %w(SEND SUBSCRIBE UNSUBSCRIBE
      BEGIN COMMIT ABORT ACK NACK DISCONNECT)
    
    # Create a new receipt scope. All receiptable frames transmitted through
    # this instance will use the same callback for handling the RECEIPT frame
    # sent by the broker.
    def initialize(parent, headers)
      super
      @receipt_ids = []
      @receipt_handler = nil
      @handler_installed = false
      @receipt_mutex = ::Mutex.new
    end
    
    # Takes a block as a callback to invoke when a receipt is received.
    def apply_to(callback)
      @receipt_handler = callback
    end
    
    # Transmits a frame. This method will add an auto-generated +receipt+ header
    # to the frame if one has not been set, and then set up a handler for the
    # +receipt+ value, invoking the callback set through {#apply_to} when
    # the corresponding RECEIPT frame is received from the broker.
    # @param [Stomper::Frame] frame
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
  
  # A "connection scope" that provides a convenient interface for handling
  # transactions. In addition to the behaviors of {HeaderScope}, for frames
  # that the Stomp protocol allows to be enclosed within a transaction, this
  # scope automatically attaches a +transaction+ header.
  class TransactionScope < HeaderScope
    # A list of frames that support being part of a transaction.
    # @return [Array<String>]
    FRAME_COMMANDS = %w(SEND BEGIN COMMIT ABORT ACK NACK)
    # The value assigned to the +transaction+ header.
    # @return [String]
    attr_reader :transaction
    
    def initialize(parent, headers)
      super
      @headers[:transaction] ||= ::Stomper::Support.next_serial
      @transaction = self.headers[:transaction]
      @transaction_state = :pending
    end
    
    # Overrides the standard {Stomper::Extensions::Commmon#begin} behavior
    # to start the transaction encapsulated by this {TransactionScope transaction}.
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
    
    # Overrides the standard {Stomper::Extensions::Commmon#abort} behavior
    # to abort the transaction encapsulated by this {TransactionScope transaction}.
    def abort_with_transaction(headers={})
      abort_without_transaction(@transaction, headers).tap do |f|
        @transaction_state = :aborted
      end
    end
    alias :abort_without_transaction :abort
    alias :abort :abort_with_transaction
    
    # Overrides the standard {Stomper::Extensions::Commmon#commit} behavior
    # to commit the transaction encapsulated by this {TransactionScope transaction}.
    def commit_with_transaction(headers={})
      commit_without_transaction(@transaction, headers).tap do |f|
        @transaction_state = :committed
      end
    end
    alias :commit_without_transaction :commit
    alias :commit :commit_with_transaction
    
    # Transmits a frame, but only applies the +transaction+ header if the
    # frame command is amongst those commands that can be included in a
    # transaction.
    # @param [Stomper::Frame] frame
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
    
    # Applies this transaction to a block. Before any transactionable frame
    # is transmitted within the block, a BEGIN frame will be generated. If
    # the block completes without raising an error, a COMMIT frame will be
    # transmitted to complete the transaction, otherwise an ABORT frame will
    # be transmitted signalling that the transaction should be rolled-back by
    # the broker.
    def apply_to(callback)
      begin
        super
        self.commit if transaction_started?
      rescue Exception => err
        self.abort if transaction_started?
        raise err
      end
    end
    
    # Returns true if a BEGIN frame has not yet been transmitted for this
    # transaction, false otherwise.
    # @return [true, false]
    def transaction_pending?; @transaction_state == :pending; end
    # Returns true if a BEGIN frame has been transmitted for this
    # transaction but neither COMMIT nor ABORT have been sent, false otherwise.
    # @return [true, false]
    def transaction_started?; @transaction_state == :started; end
    # Returns true if a COMMIT frame has been transmitted for this
    # transaction, false otherwise.
    # @return [true, false]
    def transaction_committed?; @transaction_state == :committed; end
    # Returns true if an ABORT frame has been transmitted for this
    # transaction, false otherwise.
    # @return [true, false]
    def transaction_aborted?; @transaction_state == :aborted; end
    # Returns true if a COMMIT or ABORT frame has been transmitted for this
    # transaction, false otherwise.
    # @return [true, false]
    def transaction_finalized?; transaction_aborted? || transaction_committed?; end
  end
end
