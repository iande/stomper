require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Stomper
  describe FrameReader do
    before(:each) do
      @input_stream = StringIO.new("", "w+")
      @input_stream.send(:extend, Stomper::FrameReader)
    end

    it "should produce a stomper frame" do
      @input_stream.string = "CONNECTED\n\n\0"
      @input_stream.receive_frame.should be_an_instance_of(Stomper::Frames::Connected)
    end

    it "should read headers appropriately" do
      @input_stream.string = "CONNECTED\nheader_1:a test value\nheader_2:another test value\nblather:47\n\nthe frame body\0"
      @frame = @input_stream.receive_frame
      @frame.headers.map { |(k,v)|
        [k,v]
      }.sort { |a, b| a.first.to_s <=> b.first.to_s }.should == [ [:blather, '47'], [:header_1, 'a test value'], [:header_2, 'another test value'] ]
    end

    it "should raise an exception when an invalid content-length is specified" do
      @input_stream.string = "CONNECTED\ncontent-length:3\n\nsomething more than 3 bytes long\0"
      lambda { @input_stream.receive_frame }.should raise_error(Stomper::MalformedFrameError)
    end

    it "should read the body of a message when a content length is specified" do
      @input_stream.string = "CONNECTED\ncontent-length:6\n\na test\0followed by trailing nonsense"
      @input_stream.receive_frame.body.should == "a test"
    end
    it "should read the body of a message when no content length is specified" do
      @input_stream.string = "CONNECTED\n\na bit more text and no direction\0followed by trailing nonsense"
      @input_stream.receive_frame.body.should == "a bit more text and no direction"
    end
  end
end
