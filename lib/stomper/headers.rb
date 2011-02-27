# -*- encoding: utf-8 -*-

# A specialized container for storing header name / value pairs for a Stomp
# {Stomper::Frame Frame}.  This container behaves much like a +Hash+, but
# is specialized for the Stomp protocol.  Header names are always converted
# into +String+s through the use of +to_s+ and may have more than one value
# associated with them.
#
# @note Header names are case sensitive, therefore the names 'header'
#   and 'Header' will not refer to the same values.
# @see Stomper::Support::Ruby1_8::Headers Implementation for Ruby 1.8.7
# @see Stomper::Support::Ruby1_9::Headers Implementation for Ruby 1.9
class Stomper::Headers
  include ::Enumerable
  
  # Returns a new +Hash+ object associating symbolized header names and their
  # principle values.
  # @return [Hash]
  def to_hash
    to_a.inject({}) { |h, (k,v)| h[k.to_sym] ||= v; h }
  end
end
