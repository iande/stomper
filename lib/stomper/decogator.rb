module Stomper
  module Decogator
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def delegates(*args)
        opts = args.pop
        unless opts.is_a?(Hash) && (to = opts[:to])
          raise ArgumentError, 'you must specify a receiver with the :to option'
        end
        args.each do |meth_name|
          meth = meth_name.to_sym
          module_eval <<-EOS
            def #{meth}(*args, &block)
              #{to}.send(#{meth.inspect}, *args, &block)
            end
          EOS
        end
      end

      def before(*args)
        opts = args.pop
        unless opts.is_a?(Hash) && (call = opts[:call].to_sym)
          raise ArgumentError, 'you must specify a method to call with the :call option'
        end
        args.each do |meth_name|
          meth = meth_name.to_sym
          aliased = meth_name.to_s
          meths_avail = public_instance_methods | private_instance_methods | protected_instance_methods
          while meths_avail.include?(aliased)
            prior, aliased = "without_before_#{aliased}", "before_#{aliased}"
          end
          module_eval <<-EOS
            def #{aliased}(*args, &block)
              send(#{call.inspect})
              send(#{prior.inspect}, *args, &block)
            end
          EOS
          alias_method prior, meth
          alias_method meth, aliased
        end
      end

      def around(*args)
        opts = args.pop
        unless opts.is_a?(Hash) && (call = opts[:call])
          raise ArgumentError, 'you must specify a method to call with the :call option'
        end
        args.each do |meth_name|
          meth = meth_name.to_sym
          aliased = meth_name.to_s
          meths_avail = public_instance_methods | private_instance_methods | protected_instance_methods
          while meths_avail.include?(aliased)
            prior, aliased = "without_around_#{aliased}", "around_#{aliased}"
          end
          module_eval <<-EOS
            def #{aliased}(*args, &block)
              res = nil
              send(#{call.inspect}) do
                res = send(#{prior.inspect}, *args, &block)
              end
              res
            end
          EOS
          alias_method prior, meth
          alias_method meth, aliased
        end
      end

      def after(*args)
        opts = args.pop
        unless opts.is_a?(Hash) && (call = opts[:call])
          raise ArgumentError, 'you must specify a method to call with the :call option'
        end
        args.each do |meth_name|
          meth = meth_name.to_sym
          aliased = meth_name.to_s
          meths_avail = public_instance_methods | private_instance_methods | protected_instance_methods
          while meths_avail.include?(aliased)
            prior, aliased = "without_after_#{aliased}", "after_#{aliased}"
          end
          module_eval <<-EOS
            def #{aliased}(*args, &block)
              send(#{prior.inspect}, *args, &block).tap do
                send(#{call.inspect})
              end
            end
          EOS
          alias_method prior, meth
          alias_method meth, aliased
        end
      end
    end
  end
end
