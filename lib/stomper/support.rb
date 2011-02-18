# -*- encoding: utf-8 -*-

module Stomper::Support
  # Duplicates an existing hash while transforming its keys to symbols.
  # The keys must implement the +to_sym+ method, otherwise an exception will
  # be raised. This method is used internally to convert hashes keyed with
  # Strings.
  #
  # @param [{Object => Object}] hsh The hash to convert. It's keys must respond to +to_sym+.
  # @return [{Symbol => Object}]
  # @example
  #   hash = { '10' => nil, 'key2' => [3, 5, 8, 13, 21], :other => :value }
  #   Stomper::Helpers::Hash.keys_to_sym(hash) #=> { :'10' => nil, :key2 => [3, 5, 8, 13, 21], :other => :value }
  #   hash #=> { '10' => nil, 'key2' => [3, 5, 8, 13, 21], :other => :value }
  def self.keys_to_sym(hsh)
    hsh.inject({}) do |new_hash, (k,v)|
      new_hash[k.to_sym] = v
      new_hash
    end
  end
  
  # Replaces the keys of a hash with symbolized versions.
  # The keys must implement the +to_sym+ method, otherwise an exception will
  # be raised. This method is used internally to convert hashes keyed with
  # Strings.
  #
  # @param [{Object => Object}] hsh The hash to convert. It's keys must respond to +to_sym+.
  # @return [{Symbol => Object}]
  # @example
  #   hash = { '10' => nil, 'key2' => [3, 5, 8, 13, 21], :other => :value }
  #   Stomper::Helpers::Hash.keys_to_sym!(hash) #=> { :'10' => nil, :key2 => [3, 5, 8, 13, 21], :other => :value }
  #   hash #=> { :'10' => nil, :key2 => [3, 5, 8, 13, 21], :other => :value }
  def self.keys_to_sym!(hsh)
    hsh.replace(keys_to_sym(hsh))
  end
  
  # Generates the next serial number in a thread-safe manner. This method
  # merely initializes an instance variable to 0 if it has not been set,
  # then increments this value and returns its string representation.
  def self.next_serial(prefix=nil)
    Thread.exclusive do
      @next_serial_sequence ||= 0
      @next_serial_sequence += 1
      @next_serial_sequence.to_s
    end
  end
  
  # Converts a string to the Ruby constant it names. If the +klass+ parameter
  # is a kind of +Module+, this method will return +klass+ directly.
  # @param [String,Module] klass
  # @return [Module]
  # @example
  #   Stomper::Support.constantize('Stomper::Frame') #=> Stomper::Frame
  #   Stomper::Support.constantize('This::Constant::DoesNotExist) #=> raises NameError
  #   Stomper::Support.constantize(Symbol) #=> Symbol 
  def self.constantize(klass)
    return klass if klass.is_a?(Module)
    klass.to_s.split('::').inject(Object) do |const, named|
      next const if named.empty?
      const.const_defined?(named) ? const.const_get(named) :
        const.const_missing(named)
    end
  end
end
