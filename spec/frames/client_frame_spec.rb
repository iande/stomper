require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

module Stomper::Frames
  describe ClientFrame do
    before(:each) do
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

    it "should generate content-length header when converted to a stomp frame with a non-empty body by default" do
      @frame_body = 'testing'
      @send_frame = Send.new("/queue/test/1", @frame_body)
      @send_frame.to_stomp.should == "SEND\ncontent-length:#{@frame_body.bytesize}\ndestination:/queue/test/1\n\n#{@frame_body}\0"
    end

    # What are you doing, writing a novel?
    it "should not generate a content-length header when converted to a stomp frame with a non-empty body if explicitly told to skip" do
      @frame_body = 'testing'
      @send_frame = Send.new("/queue/test/1", @frame_body)
      @send_frame.to_stomp(true).should == "SEND\ndestination:/queue/test/1\n\n#{@frame_body}\0"
    end
  end
end
