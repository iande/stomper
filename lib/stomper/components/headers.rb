# -*- encoding: utf-8 -*-

#module Stomper
  #module Components
    # A specialized container for storing header name / value pairs for a Stomp
    # {Stomper::Frame Frame}.  This container behaves much like a +Hash+, but
    # is specialized for the Stomp protocol.  Header names are always converted
    # into +String+s through the use of +to_s+ and may have more than one value
    # associated with them.
    #
    # @note Header names are case sensitive, therefore the names 'header'
    #   and 'Header' will not refer to the same values.
    class Stomper::Components::Headers
      # An array of header names ordered by when they were set.
      # @return [Array<String>]
      attr_reader :names
      include ::Enumerable
      
      # Creates a new and empty collection of headers.
      def initialize
        @values = {}
        @names = []
      end
      
      # Returns true if a header value has been set for the supplied header name.
      #
      # @param [Object] name the header name to test.
      # @return [Boolean] true if the specified header name has been set, otherwise false.
      # @example
      #   header.has? 'content-type' #=> true
      #   header.key? 'unset header' #=> false
      #   header.include? 'content-length' #=> true
      def has?(name)
        @values.key?(name.to_s)
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
      # @param [Object] name the header name associated with the desired values (will be converted using +to_s+)
      # @return [Array] the array of values associated with the header name.
      # @example
      #   headers.all_values('content-type') #=> [ 'text/plain' ]
      #   headers.all('repeated header') #=> [ 'principle value', '13', 'other value']
      #   headers['name'] == headers.all('name').first #=> true
      def all_values(name)
        @values[name.to_s] || []
      end
      alias :all :all_values
      
      # Deletes all of the header values associated with the header name and
      # removes the header name itself.  This is analogous to the +delete+
      # method found in Hash objects.
      #
      # @param [Object] name the header name to remove from this collection (will be converted using +to_s+)
      # @return [Array] the array of values associated with the deleted header, or +nil+ if the header name did not exist
      # @example
      #   headers.delete('content-type') #=> [ 'text/html' ]
      #   headers.delete('no such header') #=> nil
      def delete(name)
        name = name.to_s
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
      #   headers.append('new header', 'first value') #=> 'first value'
      #   headers.append('new header', nil) #=> ''
      #   headers.append('new header', 13) #=> '13'
      #   headers['new header'] #=> 'first value'
      #   headers.all('new header') #=> ['first value', '', '13']
      def append(name, val)
        name = name.to_s
        val = val.to_s
        if @values.key?(name)
          @values[name] << val
        else
          self[name]= val
        end
        val
      end
      
      # Gets the principle header value paired with the supplied header name. The name will
      # be converted to a String, so must respond to the +to_s+ method.  The
      # Stomp 1.1 protocol specifies that in the event of a repeated header name,
      # the first value encountered serves as the principle value.
      #
      # @param [Object] name the header name paired with the desired value (will be converted using +to_s+)
      # @return [String] the value associated with the requested header name
      # @return [nil] if no value has been set for the associated header name
      # @example
      #   headers['content-type'] #=> 'text/plain'
      def [](name)
        vals = @values[name.to_s]
        vals && vals.first
      end
      
      # Sets the header value paired with the supplied header name.  The name and
      # value will generally be converted to Strings, so must respond to the +to_s+ method.
      # Setting a header value in this fashion will overwrite any repeated header values.
      #
      # @param [Object] name the header name to associate with the supplied value (will be converted using +to_s+)
      # @param [Object] val the value to pair with the supplied name (will be converted using +to_s+)
      # @return [String] the supplied value as a string.
      # @example
      #   headers['content-type'] = 'image/png' #=> 'image/png'
      def []=(name, val)
        name = name.to_s
        val = val.to_s
        @names << name unless @values.key?(name)
        @values[name] = [val]
        val
      end
      
      # Iterates over each header name / value pair in the order in which the
      # headers names were set.  If this collection contains repeated header names,
      # the supplied block will receive those header names repeatedly, once
      # for each value.  If no block is supplied, then an +Enumerator+ is returned.
      #
      # @yield [name, value] a header name and an associated value
      # @yieldparam [String] name a header name
      # @yieldparam [String] value a value associated with the header
      # @return [Headers] +self+ if a block was supplied
      # @return [Enumerator] a collection enumerator if no block was supplied
      # @example
      #   headers['name 1'] = 'value 1'
      #   headers.append('name 2', 'value 2')
      #   headers.append('name 2', 42)
      #   headers.each { |name, val| p "#{name} - #{v}" }
      #   # name 1 - value 1
      #   # name 2 - value 2
      #   # name 2 - 42
      #   #=> #<Stomper::Components::Headers:0x0000010289d6d8>
      def each(&block)
        if block_given?
          @names.each do |name|
            @values[name].each do |val|
              yield [name, val]
            end
          end
          self
        else
          ::Enumerator.new(self)
        end
      end
    end
  #end
#end
