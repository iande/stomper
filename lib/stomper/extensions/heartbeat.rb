# -*- encoding: utf-8 -*-

# Provides the heart-beating interface for a {Stomper::Connection} object.
module Stomper::Extensions::Heartbeat
  # Extends an object with any additional modules that are appropriate
  # for the Stomp protocol being used.
  def self.extend_by_protocol_version(instance, version)
    if EXTEND_BY_VERSION[version]
      EXTEND_BY_VERSION[version].each do |mod|
        instance.extend mod
      end
    end
  end
  
  # By default, this method does nothing. If the established connection
  # utilizes the Stomp 1.1 protocol, this method will be overridden by
  # {Stomper::Protocols::V1_1::Heartbeating#beat}.
  def beat; end

  # By default, a connection is alive if it is connected.
  # If the established connection utilizes the Stomp 1.1 protocol, this
  # method will be overridden by {Stomper::Protocols::V1_1::Heartbeating#alive?}.
  # @return [true,false]
  # @see #dead?
  def alive?
    connected?
  end

  # A {Stomper::Connection connection} is dead if it is not +alive?+
  # @return [true, false]
  # @see #alive?
  def dead?
    !alive?
  end
  
  # Stomp Protocol 1.1 extensions to the heart-beating interface
  module V1_1
    # Send a heartbeat to the broker
    def beat
      transmit ::Stomper::Frame.new
    end

    # Stomp 1.1 {Stomper::Connection connections} are alive if they are
    # +connected?+ and are meeting their negotiated heart-beating obligations.
    # @return [true, false]
    # @see #dead?
    def alive?
      connected? && client_alive? && broker_alive?
    end
    
    # Maximum number of milliseconds that can pass between frame / heartbeat
    # transmissions before we consider the client to be dead.
    # @return [Fixnum]
    def heartbeat_client_limit
      unless defined?(@heartbeat_client_limit)
        @heartbeat_client_limit = heartbeating[0] > 0 ? (1.1 * heartbeating[0]) : 0
      end
      @heartbeat_client_limit
    end
    
    # Maximum number of milliseconds that can pass between frames / heartbeats
    # received before we consider the broker to be dead.
    # @return [Fixnum]
    def heartbeat_broker_limit
      unless defined?(@heartbeat_broker_limit)
        @heartbeat_broker_limit = heartbeating[1] > 0 ? (1.1 * heartbeating[1]) : 0
      end
      @heartbeat_broker_limit
    end
    
    # Returns true if the client is alive. Client is alive if client heartbeating
    # is disabled, or the number of milliseconds that have passed since last
    # transmission is less than or equal to {#heartbeat_client_limit client} limit
    # @return [true,false]
    # @see #heartbeat_client_limit
    # @see #broker_alive?
    def client_alive?
      # Consider some benchmarking to determine if this is faster than
      # re-writing the method after its first invocation.
      heartbeat_client_limit == 0 ||
        duration_since_transmitted <= heartbeat_client_limit
    end
    
    # Returns true if the broker is alive. Broker is alive if broker heartbeating
    # is disabled, or the number of milliseconds that have passed since last
    # receiving is less than or equal to {#heartbeat_broker_limit broker} limit
    # @return [true,false]
    # @see #heartbeat_broker_limit
    # @see #client_alive?
    def broker_alive?
      heartbeat_broker_limit == 0 ||
        duration_since_received <= heartbeat_broker_limit
    end
  end
  
  # A mapping between protocol versions and modules to include
  EXTEND_BY_VERSION = {
    '1.0' => [ ],
    '1.1' => [ ::Stomper::Extensions::Heartbeat::V1_1 ]
  }
end
