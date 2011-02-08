# -*- encoding: utf-8 -*-

# This class encapsulates a client connection to a message broker through the
# Stomp protocol.
class Stomper::Connection
  include ::Stomper::Extensions::Common
  include ::Stomper::Extensions::Events
  include ::Stomper::Extensions::Scoping
  
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
    :default_destination => nil,
    :ssl => {},
    :host => nil,
    :login => nil,
    :passcode => nil
  }

  # The URI representation of the broker this connection is associated with
  # @return [URI]
  attr_reader :uri
  
  # True if a connection with the broker has been established, false otherwise.
  # @return [true,false]
  attr_reader :connected
  alias :connected? :connected
  
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
  
  # The SSL options to use if this connection is secure
  # @return [{Symbol => Object}, nil]
  attr_reader :ssl
  
  # The default destination to use for subscriptions and send frames
  # when working with a connection through the +open-uri+ interface.
  # @return [String]
  attr_reader :default_destination
  
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
  #
  # @example Connecting to a broker on 'host.domain.tld' and a port of 12345
  #   con = Stomper::Connection.new('stomp://host.domain.tld:12345')
  #
  # @example Connecting with login credentials
  #   con = Stomper::Connection.new('stomp://username:secret@host.domain.tld')
  #
  # @example Connecting using a default queue for delivering SEND frames and receiving MESSAGE frames
  #   con = Stomper::Connection.new('stomp://host/queue/testing')
  #   con = Stomper::Connection.new('stomp://host/?default_destination=/queue/testing')
  #   con = Stomper::Connection.new('stomp://host', :default_destination => '/queue/testing')
  #
  # @example Connecting using Stomp protocol 1.1, sending client beats once per second, and no interest in server beats.
  #   con = Stomper::Connection.new('stomp://host/?versions=1.1&heartbeats=1000&heartbeats=0')
  #   con = Stomper::Connection.new('stomp://host', :versions => '1.1', :heartbeats => [1000, 0])
  #   # both result in:
  #   con.heartbeat #=> [1000, 0]
  #   con.version   #=> ['1.1']
  #
  # @example Repeated options in URI and options hash
  #   con = Stomper::Connection.new('stomp://host?versions=1.1&versions=1.0', :versions => '1.1')
  #   con.version #=> '1.1'
  #   # In this case, the version query parameter value +[1.1 , 1.0]+ is
  #   # overridden by the options hash setting +1.1+
  #
  #   con = Stomper::Connection.new('stomp://host/queue/lowest_priority?default_destination=/queue/middle_priority', :default_destination => '/queue/highest_priority')
  #   con.default_destination  #=> '/queue/highest_priority'
  #   # In this case, the URI's path +/queue/lowest_priority+ is overridden the
  #   # query parameter +/queue/middle_priority+, but both are overridden by
  #   # the options hash setting +/queue/highest_priority+.
  def initialize(uri, options={})
    @uri = uri.is_a?(::URI) ? uri : ::URI.parse(uri)
    config = ::Stomper::Support.keys_to_sym(::CGI.parse(uri.query)).
      merge(::Stomper::Support.keys_to_sym(options))
    DEFAULT_CONFIG.each do |attr_name, def_val|
      if config.key? attr_name
        __send__ :"#{attr_name}=", config[attr_name]
      elsif def_val
        __send__ :"#{attr_name}=", def_val
      end
    end
    @default_destination ||= (@uri.path||'')
    @host ||= (@uri.host||'localhost')
    @login ||= (@uri.user || '')
    @passcode ||= (@uri.password || '')
    @connected = false
    
    on_connected do |connected|
      version = connected[:version]
      version = '1.0' if version.nil? || version.empty?
      if @versions.include? version
        @version = version
        ::Stomper::Extensions::Protocols::EXTEND_BY_VERSION[@version].each do |mod|
          extend mod
        end
      else
        raise ::Stomper::Errors::UnsupportedProtocolVersionError, "broker requested '#{version}', client allows: #{@versions.inspect}"
      end
      @connected = true
    end
    
    before_transmitting do
      trigger_event(:on_connection_died, self) unless alive?
    end
    
    before_receiving do
      trigger_event(:on_connection_died, self) unless alive?
    end
  end
  
  # Sets the protocol versions that are acceptable for this connection. 
  # This method accepts version numbers as:
  # - A single string value (eg: '1.0')
  # - An array of string values (eg: ['1.1', '1.0'])
  #
  # @return [Array<String>] acceptable protocol versions
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
  
  # Sets the SSL options for this connection. These settings are only used
  # if the connection to the broker is secure (eg: 'stomp+ssl://...')
  def ssl=(ssl_opts)
  end
  
  # Sets the default destination for this connection. If the supplied value
  # is an array, only the first element is considered. Any value specified is
  # converted to a string.
  #
  # @param [String] val
  def default_destination=(val); @default_destination = (val.is_a?(Array) ? val.first : val).to_s; end
  
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
  def passcode=(val); @passcode = (val.is_a?(Array) ? val.first : val).to_s; end
  
  # Establishes a connection to the broker. After the socket connection is
  # established, a CONNECT/STOMP frame will be sent to the broker and a frame
  # will be read from the TCP stream. If the frame is a CONNECTED frame, the
  # connection has been established and you're ready to go, otherwise the
  # socket will be closed and an error will be raised.
  def connect
    @socket = @uri.create_socket
    transmit ::Stomper::Frame.new('CONNECT', {
      :'accept-version' => @versions.join(','),
      :host => @host,
      :'heart-beat' => @heartbeats.join(',')
    })
    connect_frame = receive
    raise ::Stomper::Errors::StomperError, 'bad juju' if connect_frame.command != 'CONNECTED'
    trigger_event(:on_connection_established, self) if @connected
    @connected
  end
  alias :open :connect
  
  # Creates a new connection and immediately connects it to the broker.
  # @see #initialize
  def self.open(uri, options={})
    conx = new(uri, options)
    conx.connect
    conx
  end
  
  # Disconnects from the broker. This is polite disconnect, in that it first
  # transmits a DISCONNECT frame before closing the underlying socket. If the
  # broker and client are using the Stomp 1.1 protocol, a receipt can be requested
  # for the DISCONNECT frame, and the connection will remain active until
  # the receipt is received or the broker closes the connection on its end.
  #
  # @param [{Symbol => String}] an optional set of headers to include in the
  #   DISCONNECT frame (these can include event handlers, such as :on_receipt)
  def disconnect(headers={})
    close_socket
  end
  alias :close :disconnect
  
  # Transmits a frame to the broker. This is a low-level method used internally
  # by the more user friendly interface.
  # @param [Stomper::Frame] frame
  def transmit(frame)
    trigger_event(:before_transmitting, self, frame)
    begin
      @socket.write_frame(frame).tap do
        trigger_event(:after_transmitting, self, frame)
        trigger_transmitted_frame(frame, self)
      end
    rescue ::IOError, ::SystemCallError
      close_socket(true)
      raise
    end
  end
  
  # Receives a frame from the broker.
  # @return [Stomper::Frame]
  def receive
    trigger_event(:before_receiving, self)
    begin
      @socket.read_frame.tap do |f|
        trigger_event(:after_receiving, self, f)
        trigger_received_frame(f, self)
      end
    rescue ::IOError, ::SystemCallError
      close_socket(true)
      raise
    end
  end
  
  # Receives a frame from the broker if there is data to be read from the
  # underlying socket. If there is no data available for reading from the
  # socket, +nil+ is returned.
  # @note While this method will not block if there is no data ready for reading,
  #   if any data is available it will block until a complete frame has been read.
  # @return [Stomper::Frame, nil]
  def receive_nonblock
    trigger_event(:before_receiving, self)
    if @socket.ready?
      @socket.read_frame.tap do |f|
        trigger_event(:after_receiving, self, f)
        trigger_received_frame(f, self)
      end
    end
  end
  
  # Move this out!
  def alive?; true; end
  def dead?; !alive?; end
  
  private
  def close_socket(fire_terminated=false)
    trigger_event(:on_connection_terminated, self) if fire_terminated
    unless @socket.closed?
      @socket.shutdown(2) rescue nil
      @socket.close rescue nil
    end
    trigger_event(:on_connection_closed, self)
  end
end
