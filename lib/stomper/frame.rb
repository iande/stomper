# -*- encoding: utf-8 -*-

# A generic encapsulation of a frame as specified by the Stomp protocol.
class Stomper::Frame
  # The command name of this frame (CONNECTED, SEND, RECEIPT, etc.)
  # @return [String]
  attr_accessor :command
  
  # The body of this frame
  # @return [String] if a body has been set
  attr_accessor :body
  
  # The headers associated with this frame
  # @return [Stomper::Headers]
  attr_reader :headers
  
  # Creates a new frame. The frame will be initialized with the optional
  # +command+ name, a {Stomper::Headers headers} collection initialized
  # with the optional +headers+ hash, and an optional body.
  def initialize(command=nil, headers={}, body=nil)
    @command = command
    @headers = ::Stomper::Headers.new(headers)
    @body = body
  end
  
  # Gets the header value paired with the supplied name.  This is a convenient
  # shortcut for `frame.headers[name]`.
  #
  # @param [Object] name the header name associated with the desired value
  # @return [String] the value associated with the requested header name
  # @see Stomper::Headers#[]
  # @example
  #   frame['content-type'] #=> 'text/plain'
  def [](name); @headers[name]; end
  
  # Sets the header value paired with the supplied name.  This is a convenient
  # shortcut for `frame.headers[name] = val`.
  #
  # @param [Object] name the header name to associate with the supplied value
  # @param [Object] val the value to associate with the supplied header name
  # @return [String] the supplied value as a string, or `nil` if `nil` was supplied as the value.
  # @see Stomper::Headers#[]=
  # @example
  #   frame['content-type'] = 'text/plain' #=> 'text/plain'
  #   frame['other header'] = 42 #=> '42'
  def []=(name, val); @headers[name] = val; end
end
