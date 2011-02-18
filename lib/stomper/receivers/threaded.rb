# -*- encoding: utf-8 -*-

# Basic threaded receiver
class Stomper::Receivers::Threaded
  attr_reader :running
  alias :running? :running
  
  def initialize(connection)
    @connection = connection
    @running = false
    @run_mutex = ::Mutex.new
    @run_thread = nil
    @raised_while_running = nil
  end
  
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
  end
  
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
  end
end
