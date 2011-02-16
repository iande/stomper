# -*- encoding: utf-8 -*-

# Manages receipt handling for a {Stomper::Connection}
class Stomper::ReceiptManager
  # Creates a new receipt handler for the supplied {Stomper::Connection connection}
  # @param [Stomper::Connection] connection
  def initialize(connection)
    connection.on_receipt { |r| dispatch(r) }
  end
  
  def dispatch(receipt)
  end
end
