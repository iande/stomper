require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Stomper
  describe FrameWriter do
    before(:each) do
      @output_buffer = StringIO.new("", "w+")
      @output_buffer.send(:extend, Stomper::FrameWriter)
    end

    it "should write commands appropriately" do
      @output_buffer.transmit_frame(Stomper::Frames::Send.new('/test/queue','body of message'))
      @output_buffer.string.should =~ /\ASEND/
    end

    it "should write headers appropriately" do
      @output_buffer.transmit_frame(Stomper::Frames::Send.new('/test/queue','body of message', :a_header => "3", :another => 23))
      split_str = @output_buffer.string.split("\n")
      split_str.shift
      headers = ['a_header:3', 'another:23', 'content-length:15', 'destination:/test/queue']
      until (header_line = split_str.shift).empty?
        headers.should include(header_line)
        headers.delete(header_line)
      end
      headers.should be_empty
    end
  end
end
