require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

module Stomper::Frames
  describe ClientFrame do
    before(:each) do
      ClientFrame.generate_content_length = true
      @client_frame = ClientFrame.new('COMMAND')
    end

    it "should be provide a headers as an instance of Headers" do
      @client_frame.headers.should be_an_instance_of(Stomper::Frames::Headers)
    end

    it "should be convertable into a stomp frame" do
      @client_frame.to_stomp.should == "COMMAND\n\n\0"
      @client_frame.headers.destination = "/queue/test/1"
      @client_frame.headers['transaction-id'] = '2'
      @client_frame.headers[:ack] = 'client'
      @client_frame.to_stomp.should == "COMMAND\nack:client\ndestination:/queue/test/1\ntransaction-id:2\n\n\0"
    end

    describe "generating content-length header" do
      it "should provide the header by default, overriding any existing header" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {'content-length' => 1}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:#{@frame_body.bytesize}\n\n#{@frame_body}\0"
      end

      it "should not provide the header if the class option is set to false, unless explicitly set on the frame in particular" do
        ClientFrame.generate_content_length = false
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\n\n#{@frame_body}\0"
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.generate_content_length = true
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:#{@frame_body.bytesize}\n\n#{@frame_body}\0"
      end

      it "should not provide the header if instance option is set false, when the class option is true" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.generate_content_length = false
        @client_frame.to_stomp.should == "COMMAND\n\n#{@frame_body}\0"
        @client_frame = ClientFrame.new('COMMAND', {:generate_content_length => false}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\n\n#{@frame_body}\0"
      end

      it "should not overwrite an explicit content-length header when option is off at class or instance level" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', { 'content-length' => 4}, @frame_body)
        @client_frame.generate_content_length = false
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:4\n\n#{@frame_body}\0"
        ClientFrame.generate_content_length = false
        @client_frame = ClientFrame.new('COMMAND', {'content-length' => 2}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:2\n\n#{@frame_body}\0"
      end

    end
  end
end
