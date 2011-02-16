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
    
  def receipt_manager; @connection.receipt_manager; end
  def subscription_manager; @connection.subscription_manager; end
end
