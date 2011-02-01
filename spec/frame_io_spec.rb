# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe FrameIO do
    before(:each) do
      @frame_io = StringIO.new
      @frame_io.extend FrameIO
    end
  
    describe "writing frames" do
      it "should properly serialize a common frame" do
        frame = mock('frame')
        frame.should_receive(:command).at_least(:once).and_return('FRAME')
        frame.should_receive(:headers).at_least(:once).and_return([ ['header_1', 'value 1'], ['header_2', 3], ['header_3'] ])
        frame.should_receive(:content_type_and_charset).at_least(:once).and_return("text/plain;charset=UTF-8")
        frame.should_receive(:body).at_least(:once).and_return('body of message')
        @frame_io.write_frame(frame)
        @frame_io.string.should == "FRAME\nheader_1:value 1\nheader_2:3\nheader_3:\ncontent-type:text/plain;charset=UTF-8\ncontent-length:15\n\nbody of message\000"
      end
      
      it "should properly serialize a frame without headers" do
        frame = mock('frame')
        frame.should_receive(:command).at_least(:once).and_return('FRAME')
        frame.should_receive(:headers).at_least(:once).and_return([])
        frame.should_receive(:content_type_and_charset).at_least(:once).and_return("text/plain;charset=UTF-8")
        frame.should_receive(:body).at_least(:once).and_return('body of message')
        @frame_io.write_frame(frame)
        @frame_io.string.should == "FRAME\ncontent-type:text/plain;charset=UTF-8\ncontent-length:15\n\nbody of message\000"
      end
      
      it "should properly serialize a frame without a body" do
        frame = mock('frame')
        frame.should_receive(:command).at_least(:once).and_return('FRAME')
        frame.should_receive(:headers).at_least(:once).and_return([ ['header_1', 'val'], ['musical', nil], ['offering', 4]])
        frame.should_receive(:content_type_and_charset).at_least(:once).and_return(nil)
        frame.should_receive(:body).at_least(:once).and_return(nil)
        @frame_io.write_frame(frame)
        @frame_io.string.should == "FRAME\nheader_1:val\nmusical:\noffering:4\n\n\000"
      end
      
      it "should properly serialize a frame without a command as a new line" do
        frame = mock('frame')
        frame.should_receive(:command).at_least(:once).and_return(nil)
        @frame_io.write_frame(frame)
        @frame_io.string.should == "\n"
      end
      
      it "should properly escape headers with special characters" do
        frame = mock('frame')
        frame.should_receive(:command).at_least(:once).and_return('FRAME')
        frame.should_receive(:headers).at_least(:once).and_return( [ ["a\ntest\nh\\eader", "value : is\n\nme"] ])
        frame.should_receive(:content_type_and_charset).at_least(:once).and_return(nil)
        frame.should_receive(:body).at_least(:once).and_return(nil)
        @frame_io.write_frame(frame)
        @frame_io.string.should == "FRAME\na\\ntest\\nh\\\\eader:value \\c is\\n\\nme\n\n\000"
      end
    end
  
    describe "reading frames" do
      before(:each) do
        @messages = {
          :content_type_and_charset => "MESSAGE\ncontent-type:text/plain; charset=ISO-8859-1\ncontent-length:6\na-header: padded \n\nh\xEBllo!\000",
          :escaped_headers => "MESSAGE\ncontent-type:text/plain;charset=UTF-8\ncontent-length:7\na\\nspecial\\chead\\\\cer: padded\\c and using\\nspecial\\\\\\\\\\\\ncharacters \n\nh\xC3\xABllo!\000",
          :no_content_length => "MESSAGE\ncontent-type:text/plain\n\nh\xC3\xABllo!\000",
          :repeated_headers => "MESSAGE\ncontent-type:text/plain\nrepeated header:a value\nrepeated header:alternate value\n\nh\xC3\xABllo!\000",
          :non_text_content_type => "MESSAGE\ncontent-type:not-text/other\n\nh\xC3\xABllo!\000",
          :no_content_type => "MESSAGE\n\nh\xC3\xABllo!\000"
        }
        @messages.each { |k, v| v.force_encoding('US-ASCII') }
      end
      it "should properly de-serialize a simple frame" do
        @frame_io.string = @messages[:content_type_and_charset]
        frame = @frame_io.read_frame
        frame.command.should == "MESSAGE"
        frame.headers.sort { |a, b| a.first <=> b.first }.should == [ ['a-header', ' padded '], ['content-length', '6'], ['content-type', 'text/plain; charset=ISO-8859-1'] ]
        frame.body.should == "hëllo!".encode("ISO-8859-1")
        frame.charset.should == 'ISO-8859-1'
      end
      it "should properly read a frame with special characters in its header" do
        @frame_io.string = @messages[:escaped_headers]
        frame = @frame_io.read_frame
        frame["a\nspecial:head\\cer"].should == " padded: and using\nspecial\\\\\\ncharacters "
        frame.charset.should == 'UTF-8'
      end
      it "should properly read a frame with a body and no content-length" do
        @frame_io.string = @messages[:no_content_length]
        frame = @frame_io.read_frame
        frame.body.should == "hëllo!"
        frame.charset.should == 'UTF-8'
      end
      it "should assume a binary charset if none is set and the content-type does not match text/*" do
        @frame_io.string = @messages[:non_text_content_type]
        frame = @frame_io.read_frame
        frame.charset.should == 'US-ASCII'
      end
      it "should assume a binary charset if the content-type header is not specified" do
        @frame_io.string = @messages[:no_content_type]
        frame = @frame_io.read_frame
        frame.charset.should == 'US-ASCII'
      end
      it "should set the value of a header to the first occurrence" do
        @frame_io.string = @messages[:repeated_headers]
        frame = @frame_io.read_frame
        frame['repeated header'].should == 'a value'
      end
    end
  end
end
