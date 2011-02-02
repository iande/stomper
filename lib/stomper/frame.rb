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
  # @return [Stomper::Components::Headers]
  attr_reader :headers
  
  # Creates a new frame with an empty set of {Stomper::Components::Headers headers}
  # and no body or command set.
  def initialize
    @headers = ::Stomper::Components::Headers.new
    @body = nil
  end
  
  # Gets the header value paired with the supplied name.  This is a convenient
  # shortcut for `frame.headers[name]`.
  #
  # @param [Object] name the header name associated with the desired value
  # @return [String] the value associated with the requested header name
  # @see Stomper::Components::Headers#[]
  # @example
  #   frame['content-type'] #=> 'text/plain'
  def [](name); @headers[name]; end
  
  # Sets the header value paired with the supplied name.  This is a convenient
  # shortcut for `frame.headers[name] = val`.
  #
  # @param [Object] name the header name to associate with the supplied value
  # @param [Object] val the value to associate with the supplied header name
  # @return [String] the supplied value as a string, or `nil` if `nil` was supplied as the value.
  # @see Stomper::Components::Headers#[]=
  # @example
  #   frame['content-type'] = 'text/plain' #=> 'text/plain'
  #   frame['other header'] = 42 #=> '42'
  def []=(name, val); @headers[name] = val; end
      
  # Returns an appropriate charset for the `body`, if one exists.
  # It is largely up to the developer to "do the right thing" with the
  # string encoding of the body.
  # ('US-ASCII', 'ASCII-8BIT', etc), this method will return 'US-ASCII' as
  # that name seems to be preferred to other aliases.  In all other cases,
  # the name of the encoding of `body` is returned without modification.
  #
  # @return [String] an appropriate charset encoding for `body`, or nil if `body` is not present.
  def charset
    if @body
      if ['ASCII-8BIT', 'US-ASCII'].include?(@body.encoding.name)
        'US-ASCII'
      else
        @body.encoding.name
      end
    end
  end

  # Gets the content-type header.  If one has not been explicitly set,
  # a guess is made based upon the presence and encoding of `body`:
  #
  # * If body is not set, return nil
  # * If body is set and has a binary charset, returns application/octet-stream
  # * Otherwise, return text/plain
  #
  # @return [String] the MIME content-type for the body of the frame.
  def content_type
    if @headers.has? 'content-type'
      @headers['content-type']
    elsif (chars = charset)
      (chars == 'US-ASCII' ? 'application/octet-stream' : 'text/plain')
    end
  end

  # Sets the content-type header to the specified value.  If +nil+ or
  # +false+ are supplied, the 'content-type' header is deleted from the
  # headers collection.
  #
  # @param [Object] ctype the MIME content-type for the body of the frame.
  def content_type=(ctype)
    if ctype
      @headers['content-type'] = ctype
    else
      @headers.delete('content-type')
    end
  end

  # Gets a combined content-type and charset string. A "best guess" will
  # be made based upon the guessing done by {#content_type} and {#charset}
  #
  # @return [String] the MIME content-type and charset for the body of the frame.
  # @see #content_type
  # @see #charset
  def content_type_and_charset
    (charset && "#{content_type};charset=#{charset}") || content_type
  end
end