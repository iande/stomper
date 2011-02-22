# -*- encoding: utf-8 -*-

# The implementation of the {Stomper::Headers} class for Ruby 1.8.7
module Stomper::Support::Ruby1_8::Headers
  # An array of header names ordered by when they were set.
  # @return [Array<String>]
  attr_reader :names
  
  # Creates a new headers collection, initialized with the optional hash
  # parameter.
  # @note With Ruby 1.8.7, the order of hash keys may not be preserved
  # @param [Hash] headers
  # @see #merge!
  def initialize(headers={})
    @values = {}
    @names = []
    merge! headers
  end
  
  # Merges a hash into this collection of headers. All of the keys used
  # in the hash must be convertable to Symbols through +to_sym+.
  # @note With Ruby 1.8.7, the order of hash keys may not be preserved
  # @param [Hash] hash
  def merge!(hash)
    hash.each { |k, v| self[k]= v }
  end
  
  # Reverse merges a hash into this collection of headers. The hash keys and
  # values are included only if the headers collection does not already have
  # a matching key. All of the keys used
  # in the hash must be convertable to Symbols through +to_sym+.
  # @note With Ruby 1.8.7, the order of hash keys may not be preserved
  # @param [Hash] hash
  def reverse_merge!(hash)
    hash.each { |k, v|
      self[k]= v unless has?(k)
    }
  end
  
  # Returns true if a header value has been set for the supplied header name.
  # @param [Object] name the header name to test (will be converted using +to_sym+)
  # @return [Boolean] true if the specified header name has been set, otherwise false.
  # @example
  #   header.has? 'content-type' #=> true
  #   header.key? 'unset header' #=> false
  #   header.include? 'content-length' #=> true
  def has?(name)
    @values.key?(name.to_sym)
  end
  alias :key? :has?
  alias :include? :has?
  
  # Retrieves all header values associated with the supplied header name.
  # In general, this will be an array containing only the principle header
  # value; however, in the event a frame contained repeated header names,
  # this method will return all of the associated values.  The first
  # element of the array will be the principle value of the supplied
  # header name.
  #
  # @param [Object] name the header name associated with the desired values (will be converted using +to_sym+)
  # @return [Array] the array of values associated with the header name.
  # @example
  #   headers.all_values('content-type') #=> [ 'text/plain' ]
  #   headers.all(:repeated_header) #=> [ 'principle value', '13', 'other value']
  #   headers['name'] == headers.all(:name).first #=> true
  def all_values(name)
    @values[name.to_sym] || []
  end
  alias :all :all_values
  
  # Deletes all of the header values associated with the header name and
  # removes the header name itself.  This is analogous to the +delete+
  # method found in Hash objects.
  #
  # @param [Object] name the header name to remove from this collection (will be converted using +to_sym+)
  # @return [Array] the array of values associated with the deleted header, or +nil+ if the header name did not exist
  # @example
  #   headers.delete(:'content-type') #=> [ 'text/html' ]
  #   headers.delete('no such header') #=> nil
  def delete(name)
    name = name.to_sym
    if @values.key? name
      @names.delete(name)
      @values.delete(name)
    end
  end
  
  # Appends a header value to the specified header name.  If the specified
  # header name is not known, the supplied value will also become the
  # principle value.  This method is used internally when constructing
  # frames sent by the broker to capture repeated header names.
  #
  # @param [Object] name the header name to associate with the supplied value (will be converted using +to_s+)
  # @param [Object] val the header value to associate with the supplied name (will be converted using +to_s+)
  # @return [String] the supplied value as a string.
  # @example
  #   headers.append(:'new header', 'first value') #=> 'first value'
  #   headers.append('new header', nil) #=> ''
  #   headers.append('new header', 13) #=> '13'
  #   headers['new header'] #=> 'first value'
  #   headers.all('new header') #=> ['first value', '', '13']
  def append(name, val)
    name = name.to_sym
    val = val.to_s
    if @values.key?(name)
      @values[name] << val
    else
      self[name]= val
    end
    val
  end
  
  # Gets the principle header value paired with the supplied header name. The name will
  # be converted to a Symbol, so must respond to the +to_sym+ method.  The
  # Stomp 1.1 protocol specifies that in the event of a repeated header name,
  # the first value encountered serves as the principle value.
  #
  # @param [Object] name the header name paired with the desired value (will be converted using +to_sym+)
  # @return [String] the value associated with the requested header name
  # @return [nil] if no value has been set for the associated header name
  # @example
  #   headers['content-type'] #=> 'text/plain'
  def [](name)
    vals = @values[name.to_sym]
    vals && vals.first
  end
  
  # Sets the header value paired with the supplied header name.  The name 
  # will be converted to a Symbol and must respond to +to_sym+; meanwhile,
  # the value will be converted to a String so must respond to +to_s+.
  # Setting a header value in this fashion will overwrite any repeated header values.
  #
  # @param [Object] name the header name to associate with the supplied value (will be converted using +to_sym+)
  # @param [Object] val the value to pair with the supplied name (will be converted using +to_s+)
  # @return [String] the supplied value as a string.
  # @example
  #   headers['content-type'] = 'image/png' #=> 'image/png'
  #   headers[:'content-type'] = nil #=> ''
  #   headers['content-type'] #=> ''
  def []=(name, val)
    name = name.to_sym
    val = val.to_s
    @names << name unless @values.key?(name)
    @values[name] = [val]
    val
  end

  # Iterates over each header name / value pair in the order in which the
  # headers names were set.  If this collection contains repeated header names,
  # the supplied block will receive those header names repeatedly, once
  # for each value. If no block is supplied, then an +Enumerator+ is returned.
  # All header names yielded through this method will be Strings and not
  # the Symbol keys used internally.
  #
  # @yield [name, value] a header name and an associated value
  # @yieldparam [String] name a header name
  # @yieldparam [String] value a value associated with the header
  # @return [Headers] +self+ if a block was supplied
  # @return [Enumerable::Enumerator] a collection enumerator if no block was supplied
  # @example
  #   headers['name 1'] = 'value 1'
  #   headers.append('name_2', 'value 2')
  #   headers.append(:name_2, 42)
  #   headers.each { |name, val| p "#{name} - #{v}" }
  #   # name 1 - value 1
  #   # name_2 - value 2
  #   # name_2 - 42
  #   #=> #<Stomper::Components::Headers:0x0000010289d6d8>
  def each(&block)
    if block_given?
      @names.each do |name|
        @values[name].each do |val|
          yield [name.to_s, val]
        end
      end
      self
    else
      ::Enumerable::Enumerator.new(self)
    end
  end
end

::Stomper::Headers.__send__(:include, ::Stomper::Support::Ruby1_8::Headers)
