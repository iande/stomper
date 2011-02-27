# -*- encoding: utf-8 -*-

# This class encapsulates a client connection to a message broker through the
# Stomp protocol. This class is also aliased as +Stomper::Client+
class Stomper::Connection
  include ::Stomper::Extensions::Common
  include ::Stomper::Extensions::Scoping
  include ::Stomper::Extensions::Events
  include ::Stomper::Extensions::Heartbeat
  
  # The list of supported protocol versions
  # @return [Array<String>]
  PROTOCOL_VERSIONS = ['1.0', '1.1']
  
  # The default configuration for connections. These settings have been
  # deliberately left unfrozen to allow users to change defaults for all
  # connections in one fell swoop.
  # @return [{Symbol => Object}]
  DEFAULT_CONFIG = {
    :versions => ['1.0', '1.1'],
    :heartbeats => [0, 0],
    :host => nil,
    :login => nil,
    :passcode => nil,
    :receiver_class => ::Stomper::Receivers::Threaded
  }

  # The URI representation of the broker this connection is associated with
  # @return [URI]
  attr_reader :uri
  
  # The CONNECTED frame sent by the broker during the connection handshake.
  # @return [Stomper::Frame,nil]
  attr_reader :connected_frame
  
  # The protocol versions to allow for this connection
  # @return [Array<String>]
  attr_reader :versions
  
  # The protocol version negotiated between the client and broker. Will be
  # +nil+ until the connection has been established.
  # @return [String,nil]
  attr_reader :version
  
  # The client-side heartbeat settings to allow for this connection
  # @return [Array<Fixnum>]
  attr_reader :heartbeats
  
  # The negotiated heartbeat strategy. The first element is the maximum
  # number of milliseconds that the client can go without transmitting
  # data or a heartbeat (a zero indicates that a client does not need to
  # send heartbeats.) The second elemenet is the maximum number of milliseconds
  # a server will go without transmitting data or a heartbeat (a zero indicates
  # that the server need not send any heartbeats.)
  # @return [Array<Fixnum>]
  attr_reader :heartbeating
  
  # The SSL options to use if this connection is secure
  # @return [{Symbol => Object}, nil]
  attr_reader :ssl
  
  # The host header value to send to the broker when connecting. This allows
  # the client to inform the server which host it wishes to connect with
  # when multiple brokers may share an IP address through virtual hosting.
  # @return [String]
  attr_reader :host
  
  # The login header value to send to the broker when connecting.
  # @return [String]
  attr_reader :login
  
  # The passcode header value to send to the broker when connecting.
  # @return [String]
  attr_reader :passcode
  
  # The class to use when instantiating a new receiver for the connection.
  # Defaults to {Stomper::Receivers::Threaded}
  # @return [CLass]
  attr_reader :receiver_class
  
  # A timestamp set to the last time a frame was transmitted. Returns +nil+
  # if no frames have been transmitted yet
  # @return [Time,nil]
  attr_reader :last_transmitted_at
  
  # A timestamp set to the last time a frame was received. Returns +nil+
  # if no frames have been received yet
  # @return [Time,nil]
  attr_reader :last_received_at
  
  # The subscription manager.  Maintains the list of destinations subscribed
  # to as well as the callbacks to invoke when a MESSAGE frame is received
  # on one of them.
  # @return [Stomper::SubscriptionManager]
  attr_reader :subscription_manager
  
  # The receipt manager.  Maintains the list of receipt IDs and the callbacks
  # associated with them that will be invoked when any frame with a matching
  # +receipt-id+ header is received.
  # @return [Stomper::ReceiptManager]
  attr_reader :receipt_manager
  
  
  # Creates a connection to a broker specified by the suppled uri. The given
  # uri will be resolved to a URI instance through +URI.parse+. The final URI object must
  # provide a {::URI::STOMP#create_socket create_socket} method, or an error
  # will be raised. Both {::URI::STOMP} and {::URI::STOMP_SSL} provide this
  # method, so string URIs with a scheme of either "stomp" or "stomp+ssl" will
  # work automatically.
  # Most connection options can be supplied through query parameters specified in the URI or
  # through an optional +Hash+ parameter. If the same option is configured in
  # both the URI's parameters and the options hash, the options hash takes
  # precedence.  Certain options, those pertaining to SSL settings for
  # instance, must be configured through the options hash.
  #
  # @param [String] uri a string representing the URI to the message broker's
  #   Stomp interface.
  # @param [{Symbol => Object}] options additional options for the connection.
  # @option options [Array<String>] :versions (['1.0', '1.1']) protocol versions
  #   this connection should allow.
  # @option options [Array<Fixnum>] :heartbeats ([0, 0]) heartbeat timings for
  #   this connection in milliseconds (a zero indicates that heartbeating is
  #   not desired from the client or the broker) 
  # @option options [{Symbol => Object}] :ssl ({}) SSL specific options to
  #   pass on when creating an {Stomper::Sockets::SSL SSL connection}.
  # @option options [String] :host (nil) Host name to pass as +host+ header
  #   on CONNECT frames (will use actual connection hostname if not set)
  # @option options [String] :login (nil) Username to send as +login+ header
  #   for credential authenticated connections.
  # @option options [String] :passcode (nil) Password to send as +passcode+ header
  #   for credential authenticated connections.
  #
  # @example Connecting to a broker on 'host.domain.tld' and a port of 12345
  #   con = Stomper::Connection.new('stomp://host.domain.tld:12345')
  #
  # @example Connecting with login credentials
  #   con = Stomper::Connection.new('stomp://username:secret@host.domain.tld')
  #
  # @example Connecting using Stomp protocol 1.1, sending client beats once per second, and no interest in server beats.
  #   con = Stomper::Connection.new('stomp://host/?versions=1.1&heartbeats=1000&heartbeats=0')
  #   con = Stomper::Connection.new('stomp://host', :versions => '1.1', :heartbeats => [1000, 0])
  #   # both result in:
  #   con.heartbeat #=> [1000, 0]
  #   con.versions   #=> ['1.1']
  #
  # @example Repeated options in URI and options hash
  #   con = Stomper::Connection.new('stomp://host?versions=1.1&versions=1.0', :versions => '1.1')
  #   con.versions #=> '1.1'
  #   # In this case, the versions query parameter value +[1.1 , 1.0]+ is
  #   # overridden by the options hash setting +1.1+
  def initialize(uri, options={})
    @ssl = options.delete(:ssl) || {}
    @uri = uri.is_a?(::URI) ? uri : ::URI.parse(uri)
    config = ::Stomper::Support.keys_to_sym(::CGI.parse(@uri.query || '')).
      merge(::Stomper::Support.keys_to_sym(options))
    DEFAULT_CONFIG.each do |attr_name, def_val|
      if config.key? attr_name
        __send__ :"#{attr_name}=", config[attr_name]
      elsif def_val
        __send__ :"#{attr_name}=", def_val
      end
    end
    @host ||= (@uri.host||'localhost')
    @login ||= (@uri.user || '')
    @passcode ||= (@uri.password || '')
    @connected = false
    @heartbeating = [0,0]
    @last_transmitted_at = @last_received_at = nil
    @subscription_manager = ::Stomper::SubscriptionManager.new(self)
    @receipt_manager = ::Stomper::ReceiptManager.new(self)
    @connecting = false
    @disconnecting = false
    @disconnected = false
    @close_mutex = ::Mutex.new
    
    on_connected do |cf, con|
      unless connected?
        @version = (cf[:version].nil?||cf[:version].empty?) ? '1.0' : cf[:version]
        unless @versions.include?(@version)
          close
          raise ::Stomper::Errors::UnsupportedProtocolVersionError,
            "broker requested '#{@version}', client allows: #{@versions.inspect}"
        end
        c_x, c_y = @heartbeats
        s_x, s_y = (cf[:'heart-beat'] || '0,0').split(',').map do |v|
          vi = v.to_i
          vi > 0 ? vi : 0
        end
        @heartbeating = [ (c_x == 0||s_y == 0 ? 0 : [c_x,s_y].max), 
          (c_y == 0||s_x == 0 ? 0 : [c_y,s_x].max) ]

        extend_for_protocol
      end
    end

    before_disconnect do |df, con|
      @disconnecting = true
    end
    on_disconnect do |df, con|
      @disconnected = true
      close unless df[:receipt]
    end
  end
  
  # Sets the protocol versions that are acceptable for this connection. 
  # This method accepts version numbers as:
  # - A single string value (eg: '1.0')
  # - An array of string values (eg: ['1.1', '1.0'])
  # @overload versions=(version)
  #   Sets the acceptable versions to a single supplied version.
  #   @param [String] version the protocol version to accept
  # @overload versions=(versions)
  #   Sets the acceptable versions to the list provided
  #   @param [Array<String>] versions list of acceptable protocol versions
  # @return [Array<String>] acceptable protocol versions
  # @raise [Stomper::Errors::UnsupportedProtocolVersionError] if none of the
  #   versions provided are supported by this library
  def versions=(vers)
    vers = [vers] unless vers.is_a?(Array)
    @versions = PROTOCOL_VERSIONS.select { |v| vers.include? v }
    if @versions.empty?
      raise ::Stomper::Errors::UnsupportedProtocolVersionError, "no supported protocol versions in #{vers.inspect}"
    end
    @versions
  end
  
  # Sets the client-side heartbeat settings to allow for this connection.
  # The first element specifies the smallest number of milliseconds between
  # heartbeats the client can guarantee, a value of 0 indicates that the client
  # cannot send heartbeats.  The second element specifies the
  # duration in milliseconds between heartbeats that the client would like
  # to receive from the server, a value of 0 indicates that the client does not
  # want to receive server heartbeats.  Both values are converted to integers,
  # and negative values are replaced with 0.
  #
  # @param [Array<Fixnum>] beats
  def heartbeats=(beats)
    @heartbeats = beats[0..1].map { |b| bi = b.to_i; bi > 0 ? bi : 0 }
  end
  
  # Sets the host header value to use when connecting to the server. This
  # provides the client with the ability to specify a specific broker that
  # resides on a server that supports virtual hosts.
  #
  # @param [String] val
  def host=(val); @host = (val.is_a?(Array) ? val.first : val).to_s; end
  
  # Sets the login header value to use when connecting to the server.
  #
  # @param [String] val
  def login=(val); @login = (val.is_a?(Array) ? val.first : val).to_s; end
  
  # Sets the passcode header value to use when connecting to the server.
  #
  # @param [String] val
  def passcode=(val)
    @passcode = (val.is_a?(Array) ? val.first : val).to_s
  end
  
  # Sets the class to use when a receiver needs to be created
  # @see #start
  # @see #stop
  # @see Stomper::Receivers::Threaded
  def receiver_class=(val)
    @receiver_class = ::Stomper::Support.constantize(val.is_a?(Array) ?
      val.first : val)
  end
  
  # Establishes a connection to the broker. After the socket connection is
  # established, a CONNECT/STOMP frame will be sent to the broker and a frame
  # will be read from the TCP stream. If the frame is a CONNECTED frame, the
  # connection has been established and you're ready to go, otherwise the
  # socket will be closed and an error will be raised.
  def connect(headers={})
    unless @connected
      @socket = @uri.create_socket(@ssl)
      @serializer = ::Stomper::FrameSerializer.new(@socket)
      m_headers = {
        :'accept-version' => @versions.join(','),
        :host => @host,
        :'heart-beat' => @heartbeats.join(','),
        :login => @login,
        :passcode => @passcode
      }
      @disconnecting = false
      @disconnected = false
      @connecting = true
      transmit create_frame('CONNECT', headers, m_headers)
      receive.tap do |f|
        if f.command == 'CONNECTED'
          @connected_frame = f
          @connected = true
          @connecting = false
          trigger_event(:on_connection_established, self)
        else
          close
          raise ::Stomper::Errors::ConnectFailedError, 'broker did not send CONNECTED frame'
        end
      end
    end
  end
  alias :open :connect
  
  class << self
    # Creates a new connection and immediately connects it to the broker.
    # @see #initialize
    def connect(uri, options={})
      conx = new(uri, options)
      conx.connect
      conx
    end
    alias :open :connect
  end
  
  # True if a connection with the broker has been established, false otherwise.
  # @return [true,false]
  def connected?
    @connected && !@socket.closed?
  end
  
  # Creates an instance of the class given by {#receiver_class} and starts it.
  # A call to {#connect} will be made if the connection has not been established.
  # The class to instantiate can be overridden on a per connection basis, or
  # for all connections by changing DEFAULT_CONFIG[:receiver_class]
  # @param [{Object => String}] headers optional headers to pass to {#connect}
  #   if the connection has not yet been established.
  # @return [self]
  # @see #stop
  # @see #connect
  def start(headers={})
    connect(headers) unless @connected
    @receiver ||= receiver_class.new(self)
    @receiver.start
    self
  end
  
  # Stops the instantiated receiver and calls {#disconnect} if a connection
  # has been established.
  # @param [{Object => String}] headers optional headers to pass to {#disconnect}
  #   if the connection has been established.
  # @return [self]
  # @raise [Exception] if invoking +stop+ on the receiver raises an exception
  # @see #start
  # @see #disconnect
  # @see Stomper::Receivers::Threaded#stop for an example of when a receiver
  #   may raise an exception when stopped.
  def stop(headers={})
    disconnect(headers) unless @disconnecting
    @receiver && @receiver.stop
    self
  end
  
  # Returns true if the receiver exists and is running.
  def running?
    @receiver && @receiver.running?
  end
  
  # Disconnects from the broker immediately. This is not a polite disconnect,
  # meaning that no DISCONNECT frame is transmitted to the broker, the socket
  # is shutdown and closed immediately. Calls to {#disconnect} invoke this
  # method internally after the DISCONNECT frame has been transmitted. This
  # method always triggers the
  # {Stomper::Extensions::Events#on_connection_closed on_connection_closed} event
  # and if +true+ is passed as a parameter,
  # {Stomper::Extensions::Events#on_connection_terminated on_connection_terminated}
  # will be triggered as well.
  # @see #disconnect
  # @see Stomper::Extensions::Events#on_connection_closed
  # @see Stomper::Extensions::Events#on_connection_terminated
  # @param [true,false] fire_terminated (false) If true, trigger
  #   {Stomper::Extensions::Events#on_connection_terminated}
  def close
    @close_mutex.synchronize do
      if @connected
        begin
          trigger_event(:on_connection_terminated, self) unless @disconnected
        ensure
          unless @socket.closed?
            @socket.shutdown(2) rescue nil
            @socket.close rescue nil
          end
          @connected = false
        end
        trigger_event(:on_connection_closed, self)
        subscription_manager.clear
        receipt_manager.clear
      end
    end
  end
  
  # Transmits a frame to the broker. This is a low-level method used internally
  # by the more user friendly interface.
  # @param [Stomper::Frame] frame
  def transmit(frame)
    trigger_event(:on_connection_died, self) if dead?
    trigger_event(:before_transmitting, frame, self)
    trigger_before_transmitted_frame(frame, self)
    begin
      @serializer.write_frame(frame).tap do
        @last_transmitted_at = Time.now
        trigger_event(:after_transmitting, frame, self)
        trigger_transmitted_frame(frame, self)
      end
    rescue ::IOError, ::SystemCallError
      close
      raise
    end
  end
  
  # Receives a frame from the broker.
  # @return [Stomper::Frame]
  def receive
    trigger_event(:on_connection_died, self) if dead?
    if alive? || @connecting
      trigger_event(:before_receiving, nil, self)
      begin
        @serializer.read_frame.tap do |f|
          if f.nil?
            close
          else
            @last_received_at = Time.now
            trigger_event(:after_receiving, f, self)
            trigger_received_frame(f, self)
          end
        end
      rescue ::IOError, ::SystemCallError
        close
        raise
      end
    end
  end
  
  # Receives a frame from the broker if there is data to be read from the
  # underlying socket. If there is no data available for reading from the
  # socket, +nil+ is returned.
  # @note While this method will not block if there is no data ready for reading,
  #   if any data is available it will block until a complete frame has been read.
  # @return [Stomper::Frame, nil]
  def receive_nonblock
    receive if @socket.ready?
  end
  
  # Duration in milliseconds since a frame has been transmitted to the broker.
  # @return [Fixnum]
  def duration_since_transmitted
    @last_transmitted_at && ((Time.now - @last_transmitted_at)*1000).to_i
  end
  
  # Duration in milliseconds since a frame has been received from the broker.
  # @return [Fixnum]
  def duration_since_received
    @last_received_at && ((Time.now - @last_received_at)*1000).to_i
  end
  
  private
  def extend_for_protocol
    ::Stomper::Extensions::Common.extend_by_protocol_version(self, @version)
    ::Stomper::Extensions::Heartbeat.extend_by_protocol_version(self, @version)
    @serializer.extend_for_protocol @version
    self
  end
end

# Alias Stomper::Client to Stomper::Connection
::Stomper::Client = ::Stomper::Connection
