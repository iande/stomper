module Stomper
  module Transactor
    # Creates a new Stomper::Transaction object and evaluates
    # the supplied +block+ within a transactional context.  If
    # the block executes successfully, the transaction is committed,
    # otherwise it is aborted.  This method is meant to provide a less
    # tedious approach to transactional messaging than the +begin+,
    # +abort+ and +commit+ methods.
    #
    # See also: Stomper::ClientInterface::begin, Stomper::ClientInterface::commit,
    # Stomper::ClientInterface::abort, Stomper::Transaction
    def transaction(transaction_id=nil, &block)
      begin
        Stomper::Transaction.new(self, transaction_id, &block)
      rescue Stomper::TransactionAborted
        nil
      end
    end
    
    # Tells the stomp broker to commit a transaction named by the
    # supplied +transaction_id+ parameter.  When used in conjunction with
    # +begin+, and +abort+, a means for manually handling transactional
    # message passing is provided.
    #
    # See Also: transaction
    def commit(transaction_id)
      transmit(Stomper::Frames::Commit.new(transaction_id))
    end

    # Tells the stomp broker to abort a transaction named by the
    # supplied +transaction_id+ parameter.  When used in conjunction with
    # +begin+, and +commit+, a means for manually handling transactional
    # message passing is provided.
    #
    # See Also: transaction
    def abort(transaction_id)
      transmit(Stomper::Frames::Abort.new(transaction_id))
    end

    # Tells the stomp broker to begin a transaction named by the
    # supplied +transaction_id+ parameter.  When used in conjunction with
    # +commit+, and +abort+, a means for manually handling transactional
    # message passing is provided.
    #
    # See also: transaction
    def begin(transaction_id)
      transmit(Stomper::Frames::Begin.new(transaction_id))
    end
  end
end
