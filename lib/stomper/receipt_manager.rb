# -*- encoding: utf-8 -*-

# Manages receipt handling for a {Stomper::Connection}
class Stomper::ReceiptManager
  # Creates a new receipt handler for the supplied {Stomper::Connection connection}
  # @param [Stomper::Connection] connection
  def initialize(connection)
    @mon = ::Monitor.new
    @callbacks = {}
    connection.on_receipt { |r| dispatch(r) }
  end
  
  # Adds a callback handler for a RECEIPT frame that matches the supplied
  # receipt ID.
  # @param [String] r_id ID of the receipt to match
  # @param [Proc] callback Proc to invoke when a matching RECEIPT frame is
  #   received from the broker.
  # @return [self]
  def add(r_id, callback)
    @mon.synchronize { @callbacks[r_id] = callback }
    self
  end
  
  private
  def dispatch(receipt)
    cb = @mon.synchronize { @callbacks.delete(receipt[:'receipt-id']) }
    cb && cb.call(receipt)
    self
  end
end
