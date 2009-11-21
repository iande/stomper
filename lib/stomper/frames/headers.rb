module Stomper
  module Frames
    class Headers
      def initialize(hsh = {})
        @intern_head = hsh.inject({}) { |acc, (k,v)| acc[k.to_sym] = v; acc }
      end

      # Override these ones, since there is a default "id" method
      def id
        @intern_head[:id]
      end

      def id=(id)
        @intern_head[:id] = id
      end

      def [](idx)
        @intern_head[idx.to_sym]
      end

      def []=(idx, val)
        @intern_head[idx.to_sym] = val
      end

      def method_missing(meth, *args)
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
