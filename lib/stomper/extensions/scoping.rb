# -*- encoding: utf-8 -*-

# Provides the scoping interface for a {Stomper::Connection} object.
module Stomper::Extensions::Scoping
  # Creates a new {Stomper::Scopes::TransactionScope} to perform
  # a transaction. If a block is provided, all SEND, ACK, NACK, COMMIT and
  # ABORT frames generated within the block are bound to the same transaction.
  # Further, if an exception is raised within the block, the transaction is
  # rolled back through an ABORT frame, otherwise it is automatically committed
  # through a COMMIT frame. If a block is not provided, the transaction must
  # be manually aborted or committed through the returned
  # {Stomper::Scopes::TransactionScope} object.
  # @param [{Symbol => Object}] headers
  # @yield [tx] block is evaluated as a transaction
  # @yieldparam [Stomper::Scopes::TransactionScope] tx
  # @return [Stomper::Scopes::TransactionScope]
  # @example Gonna need an example or two
  def with_transaction(headers={}, &block)
    create_scope(::Stomper::Scopes::TransactionScope, headers, block)
  end

  # Creates a new {Stomper::Scopes::ReceiptScope} using
  # a supplied block as the receipt handler. If no block is provided, no
  # receipt handler is created; however, all frames generated through this
  # {Stomper::Scopes::ReceiptScope} will still request a RECEIPT
  # from the broker.
  # @param [{Symbol => Object}] headers
  # @yield [receipt] callback invoked upon receiving the RECEIPT frame
  # @yieldparam [Stomper::Frame] the received RECEIPT frame
  # @return [Stomper::Scopes::ReceiptScope]
  # @example Gonna need an example or two
  # @see Stomper::Extensions::Events#on_receipt}
  def with_receipt(headers={}, &block)
    create_scope(::Stomper::Scopes::ReceiptScope, headers, block)
  end
  
  # Creates a new {Stomper::Scopes::HeaderScope} from the
  # supplied hash of headers. If a block is provided, it will be invoked with
  # with this {Stomper::Scopes::HeaderScope} as its only parameter.
  # @param [{Symbol => Object}] headers
  # @yield [header_scope] block is evaluated applying the specified headers to
  #   all frames generated within the block.
  # @yieldparam [Stomper::Scopes::HeaderScope] header_scope
  # @return [Stomper::Scopes::HeaderScope]
  # @example Gonna need an example or two
  def with_headers(headers, &block)
    create_scope(::Stomper::Scopes::HeaderScope, headers, block)
  end
  
  def create_scope(klass, headers, callback)
    klass.new(self, headers).tap do |scoped|
      scoped.apply_to(callback)
    end
  end
  private :create_scope
end
