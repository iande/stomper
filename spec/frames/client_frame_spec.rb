require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

module Stomper::Frames
  describe ClientFrame do
    before(:each) do
      ClientFrame.generate_content_length = true
      @client_frame = ClientFrame.new('COMMAND')
    end

    def str_size(str)
      str.respond_to?(:bytesize) ? str.bytesize : str.size
    end

    it "should be provide a headers as an instance of Headers" do
      @client_frame.headers.should be_an_instance_of(Stomper::Frames::Headers)
    end

    describe "generating content-length header" do
      it "should provide the header by default, overriding any existing header" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {'content-length' => 1}, @frame_body)
        @client_frame.headers_with_content_length[:'content-length'].should == str_size(@frame_body)
      end

      it "should not provide the header if the class option is set to false, unless explicitly set on the frame in particular" do
        ClientFrame.generate_content_length = false
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.headers_with_content_length[:'content-length'].should be_nil
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.generate_content_length = true
        @client_frame.headers_with_content_length[:'content-length'].should == str_size(@frame_body)
      end

      it "should not provide the header if instance option is set false, when the class option is true" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.generate_content_length = false
        @client_frame.headers_with_content_length[:'content-length'].should be_nil
        @client_frame = ClientFrame.new('COMMAND', {:generate_content_length => false}, @frame_body)
        @client_frame.headers_with_content_length[:'content-length'].should be_nil
      end

      it "should not overwrite an explicit content-length header when option is off at class or instance level" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', { 'content-length' => 4}, @frame_body)
        @client_frame.generate_content_length = false
        @client_frame.headers_with_content_length[:'content-length'].should == 4
        ClientFrame.generate_content_length = false
        @client_frame = ClientFrame.new('COMMAND', {'content-length' => 2}, @frame_body)
        @client_frame.headers_with_content_length[:'content-length'].should == 2
      end

      it "should scope the class option to the class it is set on" do
        @frame_body = 'testing'
        Send.generate_content_length = false
        @send_frame = Send.new('/queue/test/1', @frame_body)
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.headers_with_content_length[:'content-length'].should == str_size(@frame_body)
        @send_frame.headers_with_content_length[:'content-length'].should be_nil
        Send.generate_content_length = true
        ClientFrame.generate_content_length = false
        @send_frame = Send.new('/queue/test/1', @frame_body)
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.headers_with_content_length[:'content-length'].should be_nil
        @send_frame.headers_with_content_length[:'content-length'].should == str_size(@frame_body)
      end
    end
  end
end
