# -*- encoding: utf-8 -*-

# Basic threaded receiver
class Stomper::Receivers::Threaded
  # Returns true if the receiver is currently running, false otherwise.
  # If the polling thread is terminated due to a raised exception, this
  # attribute will be false.
  # @return [true,false]
  attr_reader :running
  alias :running? :running
  
  # Creates a new threaded receiver for the supplied {Stomper::Connection}.
  # Invoking {#start} on this receiver will create a new thread that will
  # continually call {Stomper::Connection#receive receive} on the
  # {Stomper::Connection connection}. Stopping this receiver with {#stop}
  # will terminate the thread.
  # @param [Stomper::Connection] connection
  def initialize(connection)
    @connection = connection
    @running = false
    @run_mutex = ::Mutex.new
    @run_thread = nil
    @raised_while_running = nil
  end
  
  # Starts the receiver by creating a new thread to continually poll the
  # {Stomper::Connection connection} for new Stomp frames. If an error is
  # raised while calling {Stomper::Connection#receive}, the polling thread
  # will terminate, and {#running?} will return false.
  # @return [self]
  def start
    is_starting = @run_mutex.synchronize { @running = true unless @running }
    if is_starting
      @run_thread = Thread.new do
        while @running
          begin
            @connection.receive
          rescue Exception => ex
            @running = false
            raise ex
          end
        end
      end
    end
    self
  end
  
  # Stops the receiver by shutting down the polling thread. If an error was
  # raised within the thread, this method will generally re-raise the error.
  # The one exception to this behavior is if the error raised was an instance
  # of +IOError+ and a call to {Stomper::Connection#connected?} returns false,
  # in which case the error is ignored. The reason for this is that performing
  # a read operation on a closed stream will raise an +IOError+. It is likely
  # that when shutting down a connection and its receiver, the polling thread
  # may be blocked on reading from the stream and raise such an error.
  # @return [self]
  # @raise [Exception]
  def stop
    stopped = @run_mutex.synchronize { @run_thread.nil? }
    unless stopped
      @running = false
      begin
        @run_thread.join
      rescue IOError
        raise if @connection.connected?
      end
      @run_thread = nil
    end
    self
  end
end
