class TestStompServer
  attr_accessor :session_class
  attr_reader :session
  
  def initialize(version=nil)
    @port = 61613
    @socket = TCPServer.new(@port)
    @session = nil
    @version = version
    @session_class = StompSession
  end
  
  def start
    @listener = Thread.new do
      begin
        @session = @session_class.new(@socket.accept, @version)
      rescue Exception => ex
        stop
      end
    end
  end
  
  def stop
    @session.stop if @session
    @socket.close rescue nil
    @listener.kill rescue nil
    @listener.join rescue nil
  end
  
  def force_stop
    @session.force_stop if @session
    @socket.close rescue nil
    @listener.kill rescue nil
    @listener.join rescue nil
  end
  
  def handle_client(client)
    
  end
  
  class StompSession
    attr_reader :received_frames, :sent_frames, :running
    alias :running? :running
    
    def initialize(client, version)
      @client_socket = client
      @received_frames = []
      @sent_frames = []
      @serializer = Stomper::Extensions::FrameSerializer.new(@client_socket)
      @running = true
      @subscribed = {}
      headers = {}
      version && headers[:version] = version
      connect_to_client(headers)
      @serializer.extend_for_protocol('1.1') if version == '1.1'
      @receive_thread = Thread.new do
        while @running
          begin
            read_frame
          rescue Exception => ex
          end
        end
      end
    end
    
    def connect_to_client(headers)
      read_frame
      send_frame 'CONNECTED', headers
    end
    
    def force_stop
      @running = false
      @client_socket.close rescue nil
      @receive_thread.join rescue nil
    end
    
    def stop
      Thread.pass while @running
      @receive_thread.join
    end
    
    def read_frame
      @serializer.read_frame.tap do |f|
        @received_frames << f
        unless f[:receipt].nil? || f[:receipt].empty?
          send_frame 'RECEIPT', { :'receipt-id' => f[:receipt] }
        end
        case f.command
        when 'DISCONNECT'
          @running = false
          @client_socket.close
        when 'SEND'
          if @subscribed[f[:destination]]
            @subscribed[f[:destination]].each_with_index do |sub_id, idx|
              msg = f.dup
              msg[:subscription] = sub_id
              msg[:'message-id'] = "m-#{(Time.now.to_f * 1000).to_i}-#{idx}"
              msg.command = 'MESSAGE'
              send_frame msg
            end
          end
        when 'SUBSCRIBE'
          @subscribed[f[:destination]] ||= []
          @subscribed[f[:destination]] << f[:id]
        when 'UNSUBSCRIBE'
          if @subscribed[f[:destination]]
            @subscribed[f[:destination]].delete f[:id]
          end
        end
      end
    end
    
    def send_frame cmd, headers={}, body=nil
      frame = cmd.is_a?(Stomper::Frame) ? cmd : Stomper::Frame.new(cmd, headers, body)
      @serializer.write_frame(frame).tap do |f|
        @sent_frames << f
      end
    end
  end
  
  class StompErrorOnConnectSession < StompSession
    def connect_to_client(headers)
      send_frame 'ERROR'
    end
  end
end

class TestSSLStompServer < TestStompServer
  SSL_CERT_FILES = {
    :default => {
      :c => File.expand_path('../ssl/broker_cert.pem', __FILE__),
      :k => File.expand_path('../ssl/broker_key.pem', __FILE__)
    }
  }
  
  def initialize(version=nil, certs=:default)
    @port = 61612
    @tcp_socket = TCPServer.new(@port)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    cert_files = SSL_CERT_FILES[certs]
    @ssl_context.key = OpenSSL::PKey::RSA.new(File.read(cert_files[:k]))
    @ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(cert_files[:c]))
    @socket = OpenSSL::SSL::SSLServer.new(@tcp_socket, @ssl_context)
    @socket.start_immediately = true
    @session = nil
    @version = version
    @session_class = StompSession
  end
end
