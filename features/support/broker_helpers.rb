module BrokerHelpers
  def create_broker(version='1.0')
    @broker_socket = TCPServer.new(61613)
    @broker_running = true
    @broker_thread = Thread.new(@broker_socket) do |serv|
      @client_socket = serv.accept
      @serializer = Stomper::Extensions::FrameSerializer.new(@client_socket)
      @serializer.read_frame
      headers = version ? { :version => version } : {}
      send_frame_to_client 'CONNECTED', headers
    end
  end
  
  def create_error_broker
    @broker_socket = TCPServer.new(61613)
    @broker_running = true
    @broker_thread = Thread.new(@broker_socket) do |serv|
      @client_socket = serv.accept
      @serializer = Stomper::Extensions::FrameSerializer.new(@client_socket)
      @serializer.read_frame
      send_frame_to_client 'ERROR'
    end
  end
  
  def destroy_broker
    @broker_thread.kill rescue nil
    @broker_thread.join rescue nil
    @broker_socket.close rescue nil
    @client_socket.close rescue nil
  end
  
  def send_frame_to_client cmd, headers={}, body=nil
    @serializer.write_frame(Stomper::Frame.new(cmd, headers, body))
  end
end


World(BrokerHelpers)