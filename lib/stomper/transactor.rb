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
  end
end
