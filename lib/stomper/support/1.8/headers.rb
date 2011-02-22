# -*- encoding: utf-8 -*-

# A specialized container for storing header name / value pairs for a Stomp
# {Stomper::Frame Frame}.  This container behaves much like a +Hash+, but
# is specialized for the Stomp protocol.  Header names are always converted
# into +String+s through the use of +to_s+ and may have more than one value
# associated with them.
#
# @note Header names are case sensitive, therefore the names 'header'
#   and 'Header' will not refer to the same values.
class Stomper::Headers
  # Iterates over each header name / value pair in the order in which the
  # headers names were set.  If this collection contains repeated header names,
  # the supplied block will receive those header names repeatedly, once
  # for each value.
  # All header names yielded through this method will be Strings and not
  # the Symbol keys used internally.
  #
  # @yield [name, value] a header name and an associated value
  # @yieldparam [String] name a header name
  # @yieldparam [String] value a value associated with the header
  # @return [Headers] +self+ if a block was supplied
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
    @names.each do |name|
      @values[name].each do |val|
        yield [name.to_s, val]
      end
    end
    self
  end
end
