module Stomper
  class TransactionAborted < RuntimeError; end

  class Transaction
    attr_reader :id
    # Inspired a bit by Rails' transactions come with a block methodology
    # However, Rails does transactions on a per-connection basis, and since
    # we'll often find that we're utilizing a single client across multiple
    # threads, we don't want to bind everything up in the same transaction,
    # so we emulate and delegate!
    # Within a transaction, every send, ack, abort and commit command
    # should be given the same transaction id.  Keep an eye on nesting
    # transasctions, as the stomp protocol has been kind enough to let us
    # name our transactions.
    def initialize(client, trans_id=nil, &block)
      @client = client
      @id = trans_id || "tx-#{Time.now.to_f}"
      @committed = false
      @aborted = false
      perform(&block) if block_given?
    end

    def perform(&block)
      begin
        @client.begin(@id)
        if block.arity == 1
          yield self
        else
          instance_eval(&block)
        end
        commit
      rescue => err
        abort
        # If the transaction aborts, raise a new exception.
        # If this is a nested transaction, we can abort the parent as well
        # If we are directly using Transaction objects, we will need to handle
        # this exception.
        raise TransactionAborted, "aborted transaction '#{@id}' originator: #{err.to_s}"
      end
    end
    
    def committed?
      @committed
    end
    
    def aborted?
      @aborted
    end

    # Atomicity within atomicity!
    def transaction(transaction_id=nil,&block)
      # To get a transaction name guaranteed to not collide with this one
      # we will supply an explicit id to the constructor unless an id was
      # provided
      transaction_id ||= "#{@id}-#{Time.now.to_f}"
      self.class.new(@client, transaction_id, &block)
    end

    def send(destination, body, headers={})
      headers['transaction'] = @id
      @client.send(destination, body, headers)
    end

    def ack(message_or_id, headers={})
      headers['transaction'] = @id
      @client.ack(message_or_id, headers)
    end

    def abort
      # Guard against sending multiple abort messages to the server for a
      # single transaction.
      @client.abort(@id) unless committed? || aborted?
      @aborted = true
    end

    def commit
      # Guard against sending multiple commit messages to the server for a
      # single transaction.
      @client.commit(@id) unless committed? || aborted?
      @committed = true
    end
  end
end
