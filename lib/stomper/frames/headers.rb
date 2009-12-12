module Stomper
  module Frames
    # Encapsulates the headers attached to a Frame from the Stomper::Frames
    # module.  Instances of this class wrap a hash, but do so in a way
    # to allow its values to be accessed by string, symbol, or method name,
    # similar to an OpenStruct.
    class Headers
      # Creates a new Header instance, derived from the supplied hash, +hsh+.
      def initialize(hsh = {})
        @intern_head = hsh.inject({}) { |acc, (k,v)| acc[k.to_sym] = v; acc }
      end

      # Returns the 'id' header value, if it exists.  Explicitly implemented
      # because Object#id is a valid method by default.
      def id
        @intern_head[:id]
      end

      # Assigns the 'id' header value.  Explicitly implemented because Object#id
      # is a valid method, and we implemented +id+ explicitly so why not +id=+
      def id=(id)
        @intern_head[:id] = id
      end

      # Allows the headers to be accessed as though they were a Hash instance.
      def [](idx)
        @intern_head[idx.to_sym]
      end

      # Allows the headers to be assigned as though they were a Hash instance.
      def []=(idx, val)
        @intern_head[idx.to_sym] = val
      end

      def method_missing(meth, *args) # :nodoc:
        raise TypeError, "can't modify frozen headers" if frozen?
        meth_str = meth.to_s
        ret = if meth_str =~ /=$/
          raise ArgumentError, "setter #{meth_str} can only accept one value" if args.size != 1
          meth_str.chop!
          @intern_head[meth_str.to_sym] = args.first
        else
          raise ArgumentError, "getter #{meth_str} cannot accept any values" if args.size > 0
          @intern_head[meth_str.to_sym]
        end
        _create_helpers(meth_str)
        # Do the appropriate thing the first time around.
        ret
      end

      # Converts the headers encapsulated by this object into a format that
      # the Stomp Protocol expects them to be presented as.
      def to_stomp
        @intern_head.sort { |a, b| a.first.to_s <=> b.first.to_s }.inject("") do |acc, (k,v)|
          acc << "#{k.to_s}:#{v}\n"
        end
      end

      protected
      def _create_helpers(meth)
        return if self.respond_to?(meth)
        meta = class << self; self; end
        meta.send(:define_method, meth) { self[meth] }
        meta.send(:define_method, :"#{meth}=") { |v| self[meth] = v }
      end
    end
  end
end
