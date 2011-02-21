# -*- encoding: utf-8 -*-

# A "connection scope" that provides much of the same interface as 
# {Stomper::Connection}, but automatically applies header name/value pairs
# to all frames generated on the scope.
class ::Stomper::Scopes::HeaderScope
  include ::Stomper::Extensions::Common

  # The underlying {Stomper::Connection connection} to transmit frames through.
  # @return [Stomper::Connection]
  attr_reader :connection
  # The headers to apply to all frames generated on this scope.
  # @return [{Symbol => String}]
  attr_reader :headers
  
  # Creates a new {Stomper::Scopes::HeaderScope}.  The supplied +headers+ hash will have
  # all of its keys converted to symbols and its values converted to strings,
  # so the key/value pairs must support this transformation (through +to_sym+
  # and +to_s+, respectively.)
  # @param [Stomper::Connection] connection
  # @param [{Object => String}] headers
  def initialize(connection, headers)
    @headers = ::Stomper::Support.keys_to_sym(headers)
    @connection = connection
    ::Stomper::Extensions::Common.extend_by_protocol_version(self, @connection.version)
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
  
  # Returns the connection's {Stomper::ReceiptManager}
  # @return [Stomper::ReceiptManager]
  def receipt_manager; @connection.receipt_manager; end
  
  # Returns the connection's {Stomper::SubscriptionManager}
  # @return [Stomper::SubscriptionManager]
  def subscription_manager; @connection.subscription_manager; end
end
