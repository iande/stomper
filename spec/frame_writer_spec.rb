require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Stomper
  describe FrameWriter do
    before(:each) do
      @output_buffer = StringIO.new("", "w+")
      @frame_writer = FrameWriter.new(@output_buffer)
    end

    it "should write commands appropriately" do
      @frame_writer.put_frame(Stomper::Frames::Send.new('/test/queue','body of message'))
      @output_buffer.string.should =~ /\ASEND/
    end

    it "should write headers appropriately" do
      @frame_writer.put_frame(Stomper::Frames::Send.new('/test/queue','body of message', :a_header => "3", :another => 23))
      @output_buffer.string.should == "SEND\na_header:3\nanother:23\ncontent-length:15\ndestination:/test/queue\n\nbody of message\0"
    end
  end
end
