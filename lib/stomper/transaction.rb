module Stomper
  # An exception raised whenever a Transaction object has been aborted
  # due to an unhandled exception generated by its supplied block, or when
  # the block explicitly aborts the transaction.
  #
  # See also: Stomper::Transaction#perform
  class TransactionAborted < RuntimeError; end

  # An encapsulation of a stomp transaction.  Manually managing transactions
  # is possible through the use of Stomper::Client#begin, Stomper::Client#commit,
  # and Stomper::Client#abort.
  #
  # === Example Usage
  #
  # When the transaction is passed to the block:
  #
  #   client.transaction do |t|
  #     t.send("/queue/target", "doing some work")
  #
  #     # do something that might raise an exception, indicating that any
  #     # messages and acknowledgements we have sent should be "undone"
  #
  #     t.send("/queue/target", "completed work")
  #   end
  #
  # When the block is evaluated within the transaction:
  #
  #   client.transaction do
  #     send("/queue/target", "doing some work")
  #
  #     # ...
  #
  #     send("/queue/target", "completed work")
  #   end
  #
  # Nesting transactions:
  #
  #   client.transaction do |t|
  #     t.transaction do |nt|
  #       nt.send("/queue/target", ...)
  #
  #       nt.transaction do |nnt|
  #         nnt.send("/queue/target", ...)
  #
  #         # do something with potentially exceptional results
  #       end
  #
  #       nt.send("/queue/target", ...)
  #     end
  #
  #     t.send("/queue/target", ...)
  #   end
  #
  # See also: Stomper::Client#transaction
  #
  class Transaction
    # The id of this transaction, used to reference the transaction with the stomp broker.
    attr_reader :id

    # Creates a new Transaction instance.  The +client+ parameter
    # is an instance of Stomper::Client and is required so that the Transaction
    # instance has somewhere to forward +begin+, +ack+ and +abort+ methods
    # to.  If the +trans_id+ parameter is not specified, an id is automatically
    # generated of the form "tx-{Time.now.to_f}".  This name can be accessed
    # through the +id+ attribute and is used in naming the transaction to
    # the stomp broker.  If +block+ is given, the Transaction instance immediately
    # calls its perform method with the supplied +block+.
    def initialize(client, trans_id=nil, &block)
      @client = client
      @id = trans_id || "tx-#{Time.now.to_f}"
      @committed = false
      @aborted = false
      perform(&block) if block_given?
    end

    # Invokes the given +block+.  If the +block+ executes normally, the
    # transaction is committed, otherwise it is aborted.
    # If +block+ accepts a parameter, this method yields itself to the block,
    # otherwise, +block+ is evaluated within the context of this instance through
    # +instance_eval+.
    #
    # If a call to +abort+ is issued within the block, the transaction is aborted
    # as demanded, and no attempt is made to commit it; however, no code after the
    # call to +abort+ will be evaluated, as +abort+ raises a TransactionAborted
    # exception.
    #
    # If a call to +commit+ is issued within the block, the transaction is committed
    # as demanded, and no attempt is made to commit it after +block+ has finished
    # executing.  As +commit+ does not raise an excpetion, all code after the call
    # to commit will be evaluated.
    #
    # If you are using Transaction objects directly, and not relying on their
    # generation through Stomper::Client#transaction, be warned that this method
    # will raise a TransactionAborted exception if the +block+ evaluation fails.
    # This behavior allows for nesting transactions and ensuring that if a nested
    # transaction fails, so do all of its ancestors.
    #
    # @param [Proc] block A block of code that is evaluated as part of the transaction.
    # @raise [TransactionAborted] raises an exception if the given block raises an exception
    def perform(&block) #:yields: transaction
      begin
        @client.begin(@id)
        if block.arity == 1
          yield self
        else
          instance_eval(&block)
        end
        commit
      rescue => err
        _abort
        raise TransactionAborted, "aborted transaction '#{@id}' originator: #{err.to_s}"
      end
    end

    # Returns true if the Transaction object has already been committed, false
    # otherwise.
    def committed?
      @committed
    end

    # Returns true if the Transaction object has already been aborted, false
    # otherwise.
    def aborted?
      @aborted
    end

    # Similar to Stomper::Client#transaction, this method creates a new
    # Transaction object, nested inside of this one.  To prevent name
    # collisions, this method automatically generates a transaction id,
    # if one is not specified, of the form "#{parent_transaction_id}-#{Time.now.to_f}.
    def transaction(transaction_id=nil,&block)
      # To get a transaction name guaranteed to not collide with this one
      # we will supply an explicit id to the constructor unless an id was
      # provided
      transaction_id ||= "#{@id}-#{Time.now.to_f}"
      self.class.new(@client, transaction_id, &block)
    end

    # Wraps the Stomper::Client#send method, injecting a "transaction" header
    # into the +headers+ hash, thus informing the stomp broker that the message
    # generated here is part of this transaction.
    def send(destination, body, headers={})
      @client.send(destination, body, headers.merge({:transaction => @id }))
    end

    # Wraps the Stomper::Client#ack method, injecting a "transaction" header
    # into the +headers+ hash, thus informing the stomp broker that the message
    # acknowledgement is part of this transaction.
    def ack(message_or_id, headers={})
      @client.ack(message_or_id, headers.merge({ :transaction => @id }))
    end

    # Aborts this transaction if it has not already been committed or aborted.
    # Note that it does so by raising a TransactionAborted exception, allowing
    # the +abort+ call to force any ancestral transactions to also fail.
    #
    # @see Transaction#commit
    # @see Transaction#committed?
    # @see Transaction#aborted?
    def abort
      raise TransactionAborted, "transaction '#{@id}' aborted explicitly" if _abort
    end

    # Commits this transaction unless it has already been committed or aborted.
    #
    # @see Transaction#abort
    # @see Transaction#committed?
    # @see Transaction#aborted?
    def commit
      # Guard against sending multiple commit messages to the server for a
      # single transaction.
      @client.commit(@id) unless committed? || aborted?
      @committed = true
    end

    private
    def _abort
      # Guard against sending multiple abort messages to the server for a
      # single transaction.
      return false if committed? || aborted?
      @client.abort(@id)
      @aborted = true
    end
  end
end
