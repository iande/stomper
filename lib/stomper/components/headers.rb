# -*- encoding: utf-8 -*-
module Stomper
  module Components
    class Headers
      attr_reader :names
      include ::Enumerable
      
      def initialize
        @values = {}
        @names = []
      end
      
      # Returns true if a header value has been set for the supplied header name
      #
      # @param [Object] name the header name to test.
      # @return [Boolean] true if the specified header name has been set, otherwise false.
      # @example
      #   header.has? 'content-type' #=> true
      #   header.key? 'unset header' #=> false
      def has?(name)
        @values.key?(name.to_s)
      end
      alias :key? :has?
      alias :include? :has?
      
      # Retrieves all header values associated with the supplied header name.
      # In general, this will be an array containing only the principle header
      # value; however, in the event a frame contained repeated header names,
      # this method will return all of the associated values.  In the event that
      # a `nil` value was assigned to a header, this method will return an empty
      # array.  The first element of the array will be the principle value of
      # the supplied header name.
      #
      # @param [Object] name the header name associated with the desired values (will be converted using `to_s`)
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
      # removes the header name itself.  This is analogous to the `delete`
      # method found in Hash objects.
      #
      # @param [Object] name the header name to remove from this collection (will be converted using `to_s`)
      # @return [Array] the array of values associated with the deleted header, or `nil` if the header name did not exist
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
      # @param [Object] name the header name to associate with the supplied value (will be converted using `to_s`)
      # @param [Object] val the header value to associate with the supplied name (will be converted using `to_s` unless `nil` is supplied)
      # @return [String] the supplied value as a string (or `nil` if `nil` was supplied as the value)
      # @example
      #   headers.append('new header', 'first value') #=> 'first value'
      #   headers.append('new header', 13) #=> '13'
      #   headers['new header'] #=> 'first value'
      #   headers.all('new header') #=> ['first value', '13']
      def append(name, val)
        name = name.to_s
        if @values.key?(name)
          @values[name] << (val && val.to_s)
        else
          self[name]= val
        end
        @values[name].last
      end
      
      # Gets the principle header value paired with the supplied header name. The name will
      # be converted to a String, so must respond to the `to_s` method.  The
      # Stomp 1.1 protocol specifies that in the event of a repeated header name,
      # the first value encountered serves as the principle value.
      #
      # @param [Object] name the header name paired with the desired value (will be converted using `to_s`)
      # @return [String] the value associated with the requested header name
      # @example
      #   headers['content-type'] #=> 'text/plain'
      def [](name)
        vals = @values[name.to_s]
        vals && vals.first
      end
      
      # Sets the header value paired with the supplied header name.  The name and
      # value will generally be converted to Strings, so must respond to the `to_s` method.
      # If the header value is nil, the value will not be converted to a string and
      # the associated header name will have an empty value.  Setting a header value
      # in this fashion will overwrite any repeated header values.
      #
      # @param [Object] name the header name to associate with the supplied value (will be converted using `to_s`)
      # @param [Object] val the value to pair with the supplied name (will be converted using `to_s`, unless `nil` is supplied)
      # @return [String] the supplied value as a string (or `nil` if `nil` was supplied as the value)
      # @example
      #   headers['content-type'] = 'image/png' #=> 'image/png'
      def []=(name, val)
        name = name.to_s
        @names << name unless @values.key?(name)
        if val.nil?
          @values[name] = []
        else
          @values[name] = [val.to_s]
        end
        @values[name].first
      end
      
      def each(&block)
        if block_given?
          @names.each do |name|
            @values[name].each do |val|
              yield [name, val]
            end
          end
        else
          ::Enumerator.new(self)
        end
      end
    end
  end
end
