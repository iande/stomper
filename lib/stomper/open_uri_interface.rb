module Stomper
  module OpenUriInterface
    def put(msg, headers={})
      send(default_destination, msg, headers.merge(:generate_content_length => false))
    end
    alias_method :puts, :put

    def write(msg, headers={})
      send(default_destination, msg, headers.merge(:generate_content_length => true))
    end

    def first(n=1)
      received = []
      each do |m|
        received << m
        break if received.size == n
      end
      n == 1 ? received.first : received
    end
    alias_method :get, :first
    alias_method :gets, :first
    alias_method :read, :first

    # This is the tricky one.
    # The subscriber interface is not going to work here, because it is built
    # for an entirely different use case (threaded receiving)
    # This interface, by contrast, is blocking... fudge.
    def each(&block)
      subscription = subscribe(default_destination) { |m| m }
      loop do
        m = receive
        yield m if m.is_a?(Stomper::Frames::Message) && subscription.accepts?(m)
      end
    end

    private
    def default_destination
      uri.path
    end
  end
end
