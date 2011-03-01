# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe FrameSerializer do
    before(:each) do
      @messages = {
        :content_type_and_charset => "MESSAGE\ncontent-type:text/plain; charset=ISO-8859-1\ncontent-length:6\na-header: padded \n\nh\xEBllo!\000",
        :escaped_headers => "MESSAGE\ncontent-type:text/plain;charset=UTF-8\ncontent-length:7\na\\nspecial\\chead\\\\cer: padded\\c and using\\nspecial\\\\\\\\\\\\ncharacters \n\nh\xC3\xABllo!\000",
        :no_content_length => "MESSAGE\ncontent-type:text/plain\n\nh\xC3\xABllo!\000",
        :repeated_headers => "MESSAGE\ncontent-type:text/plain\nrepeated header:a value\nrepeated header:alternate value\n\nh\xC3\xABllo!\000",
        :non_text_content_type => "MESSAGE\ncontent-type:not-text/other\n\nh\xC3\xABllo!\000",
        :no_content_type => "MESSAGE\n\nh\xC3\xABllo!\000",
        :invalid_content_length => "MESSAGE\ncontent-length:4\n\n12345\000",
        :invalid_header_character => "MESSAGE\ngrandpa:he was:anti\n\n12345\000",
        :invalid_header_sequence => "MESSAGE\ngrandpa:he was\\ranti\n\n12345\000",
        :malformed_header => "MESSAGE\nearth_below_us\nfloating:weightless\n\n12345\000",
        :dangling_header_sequence => "MESSAGE\ngrandpa:he was anti\\\n\n12345\000",
      }
    
      @frames = {
        :common => ::Stomper::Frame.new('FRAME', {}, 'body of message'),
        :no_headers => ::Stomper::Frame.new('FRAME', {}, 'body of message'),
        :no_body => ::Stomper::Frame.new('FRAME', {}),
        :no_command => ::Stomper::Frame.new,
        :header_name_with_linefeed => ::Stomper::Frame.new('FRAME', { "a\ntest\nheader" => "va\\lue : is\n\nme"}),
        :header_name_with_colon => ::Stomper::Frame.new('FRAME', { "a:test:header" => "va\\lue : is\n\nme"}),
        :header_name_with_backslash => ::Stomper::Frame.new('FRAME', { "a\\test\\header" => "va\\lue : is\n\nme"}),
        :binary_body_no_content_type => ::Stomper::Frame.new('FRAME', {}, 'body of message'),
        :charset_header_text_body => ::Stomper::Frame.new('FRAME', {:'content-type' => 'text/plain; param="value";charset=ISO-8859-1'}, 'body of message'),
        :charset_header_binary_body => ::Stomper::Frame.new('FRAME', {:'content-type' => 'application/pdf; param="value";charset=ISO-8859-1'}, 'body of message')
      }
      # Curse Ruby 1.8.7 and it's unordered hashes!
      @frames[:common][:header_1] = 'value 1'
      @frames[:common][:header_2] = '3'
      @frames[:common][:header_3] = ''
      @frames[:common][:'content-type'] = 'text/plain'
      @frames[:no_body][:header_1] = 'val'
      @frames[:no_body][:musical] = ''
      @frames[:no_body][:offering] = '4'
      if RUBY_VERSION >= "1.9"
        @messages.each { |k, v| v.force_encoding('ASCII-8BIT') }
        @frames[:no_headers].body = @frames[:no_headers].body.encode('ISO-8859-1')
        @frames[:binary_body_no_content_type].body = @frames[:binary_body_no_content_type].body.encode('ASCII-8BIT')
        @frames[:charset_header_binary_body].body = @frames[:charset_header_binary_body].body.encode('ASCII-8BIT')
        @frames[:charset_header_text_body].body = @frames[:charset_header_text_body].body.encode('UTF-8')
      end
      @frame_io = StringIO.new
      @frame_serializer = FrameSerializer.new(@frame_io)
    end
  
    describe "thread safety" do
      before(:each) do
        @frame_serializer = FrameSerializer.new(mock('frame io'))
      end
      it "should synchronize writing to the underlying IO" do
        first_called = false
        call_next = false
        ordered = []
        @frame_serializer.stub!(:__write_frame__).and_return do |f|
          first_called = true
          ordered << 1
          Thread.stop
          ordered << 2
          f
        end
      
        thread_1 = Thread.new do
          @frame_serializer.write_frame(mock('frame'))
        end
        thread_2 = Thread.new do
          Thread.pass until call_next
          Thread.pass
          thread_1.run
        end
        Thread.pass until first_called
        call_next = true
      
        @frame_serializer.stub!(:__write_frame__).and_return do |f|
          ordered << 3
          f
        end
        @frame_serializer.write_frame(mock('frame'))
        thread_1.join
        thread_2.join
        ordered.should == [1, 2, 3]
      end
    
      it "should synchronize reading from the underlying IO" do
        first_called = false
        call_next = false
        ordered = []
        @frame_serializer.stub!(:__read_frame__).and_return do
          first_called = true
          ordered << 1
          Thread.stop
          ordered << 2
          mock('frame 1')
        end
      
        thread_1 = Thread.new do
          @frame_serializer.read_frame
        end
        thread_2 = Thread.new do
          Thread.pass until call_next
          Thread.pass
          thread_1.run
        end
        Thread.pass until first_called
        call_next = true
      
        @frame_serializer.stub!(:__read_frame__).and_return do
          ordered << 3
          mock('frame 2')
        end
        @frame_serializer.read_frame
        thread_1.join
        thread_2.join
        ordered.should == [1, 2, 3]
      end
    
      it "should not make reading and writing mutually exclusive" do
        first_called = false
        call_next = false
        ordered = []
        @frame_serializer.stub!(:__write_frame__).and_return do |f|
          first_called = true
          ordered << 1
          Thread.stop
          ordered << 2
          f
        end
        @frame_serializer.stub!(:__read_frame__).and_return do
          ordered << 3
          mock('frame 2')
        end
      
        thread_1 = Thread.new do
          @frame_serializer.write_frame(mock('frame'))
        end
        thread_2 = Thread.new do
          Thread.pass until call_next
          Thread.pass
          thread_1.run
        end
        Thread.pass until first_called
        call_next = true
        @frame_serializer.read_frame
        thread_1.join
        thread_2.join
        ordered.should == [1, 3, 2]
      end
    end
  
    describe "Protocol 1.0" do
      it "should not have extended the V1_1 mixin" do
        ::Stomper::FrameSerializer::EXTEND_BY_VERSION['1.1'].each do |mod|
          @frame_serializer.should_not be_a_kind_of(mod)
        end
      end
    
      describe "writing frames" do
        it "should properly serialize a common frame" do
          @frame_serializer.write_frame(@frames[:common])
          @frame_io.string.should == "FRAME\nheader_1:value 1\nheader_2:3\nheader_3:\ncontent-type:text/plain;charset=UTF-8\ncontent-length:15\n\nbody of message\000"
        end
    
        it "should properly serialize a frame without headers" do
          @frame_serializer.write_frame(@frames[:no_headers])
          expected = RUBY_VERSION >= '1.9' ? "FRAME\ncontent-type:text/plain;charset=ISO-8859-1\ncontent-length:15\n\nbody of message\000" :
            "FRAME\ncontent-length:15\n\nbody of message\000"
          @frame_io.string.should == expected
        end
    
        it "should properly serialize a frame without a body" do
          @frame_serializer.write_frame(@frames[:no_body])
          @frame_io.string.should == "FRAME\nheader_1:val\nmusical:\noffering:4\n\n\000"
        end
    
        it "should properly serialize a frame without a command as a new line" do
          @frame_serializer.write_frame(@frames[:no_command])
          @frame_io.string.should == "\n"
        end
    
        it "should properly drop LF from header names and values" do
          @frame_serializer.write_frame(@frames[:header_name_with_linefeed])
          @frame_io.string.should == "FRAME\natestheader:va\\lue : isme\n\n\000"
        end
      
        it "should not escape backslash characters in header names or values" do
          @frame_serializer.write_frame(@frames[:header_name_with_backslash])
          @frame_io.string.should == "FRAME\na\\test\\header:va\\lue : isme\n\n\000"
        end
      
        it "should drop colons in header names, but leave them alone in values" do
          @frame_serializer.write_frame(@frames[:header_name_with_colon])
          @frame_io.string.should == "FRAME\natestheader:va\\lue : isme\n\n\000"
        end
      
        it "should not generate a content-type header if the encoding is binary" do
          @frame_serializer.write_frame(@frames[:binary_body_no_content_type])
          @frame_io.string.should == "FRAME\ncontent-length:15\n\nbody of message\000"
        end
      
        it "should overwrite the charset parameter with the encoding when the body is text" do
          @frame_serializer.write_frame(@frames[:charset_header_text_body])
          expected = RUBY_VERSION >= '1.9' ? "FRAME\ncontent-type:text/plain; param=\"value\";charset=UTF-8\ncontent-length:15\n\nbody of message\000" :
            "FRAME\ncontent-type:text/plain; param=\"value\";charset=ISO-8859-1\ncontent-length:15\n\nbody of message\000"
          @frame_io.string.should == expected
        end
      
        it "should omit the charset parameter when the content-type is not text/* and the encoding is binary" do
          @frame_serializer.write_frame(@frames[:charset_header_binary_body])
          expected = RUBY_VERSION >= '1.9' ? "FRAME\ncontent-type:application/pdf; param=\"value\"\ncontent-length:15\n\nbody of message\000" :
            "FRAME\ncontent-type:application/pdf; param=\"value\";charset=ISO-8859-1\ncontent-length:15\n\nbody of message\000"
          @frame_io.string.should == expected
        end
      end
    end
  
    describe "Protocol 1.1" do
      before(:each) do
        @frame_serializer.extend_for_protocol '1.1'
      end
    
      it "should have extended the V1_1 mixin" do
        ::Stomper::FrameSerializer::EXTEND_BY_VERSION['1.1'].each do |mod|
          @frame_serializer.should be_a_kind_of(mod)
        end
      end

      describe "writing frames" do
        it "should properly serialize a common frame" do
          @frame_serializer.write_frame(@frames[:common])
          @frame_io.string.should == "FRAME\nheader_1:value 1\nheader_2:3\nheader_3:\ncontent-type:text/plain;charset=UTF-8\ncontent-length:15\n\nbody of message\000"
        end
    
        it "should properly serialize a frame without headers" do
          @frame_serializer.write_frame(@frames[:no_headers])
          expected = RUBY_VERSION >= '1.9' ? "FRAME\ncontent-type:text/plain;charset=ISO-8859-1\ncontent-length:15\n\nbody of message\000" :
            "FRAME\ncontent-length:15\n\nbody of message\000"
          @frame_io.string.should == expected
        end
    
        it "should properly serialize a frame without a body" do
          @frame_serializer.write_frame(@frames[:no_body])
          @frame_io.string.should == "FRAME\nheader_1:val\nmusical:\noffering:4\n\n\000"
        end
    
        it "should properly serialize a frame without a command as a new line" do
          @frame_serializer.write_frame(@frames[:no_command])
          @frame_io.string.should == "\n"
        end
      
        it "should escape LF in header names and values" do
          @frame_serializer.write_frame(@frames[:header_name_with_linefeed])
          @frame_io.string.should == "FRAME\na\\ntest\\nheader:va\\\\lue \\c is\\n\\nme\n\n\000"
        end
      
        it "should escape backslashes in header names and values" do
          @frame_serializer.write_frame(@frames[:header_name_with_backslash])
          @frame_io.string.should == "FRAME\na\\\\test\\\\header:va\\\\lue \\c is\\n\\nme\n\n\000"
        end
      
        it "should escape colons in header names and values" do
          @frame_serializer.write_frame(@frames[:header_name_with_colon])
          @frame_io.string.should == "FRAME\na\\ctest\\cheader:va\\\\lue \\c is\\n\\nme\n\n\000"
        end
      end

      describe "reading frames" do
        it "should properly de-serialize a simple frame" do
          @frame_io.string = @messages[:content_type_and_charset]
          frame = @frame_serializer.read_frame
          frame.should have_command('MESSAGE')
          frame.should have_header(:'a-header', ' padded ')
          frame.should have_header(:'content-length', '6')
          frame.should have_header(:'content-type', 'text/plain; charset=ISO-8859-1')
          frame.should have_body("hëllo!", "h\xEBllo!", 'ISO-8859-1')
          frame.should have_body_encoding('ISO-8859-1')
        end
        it "should properly read a frame with special characters in its header" do
          @frame_io.string = @messages[:escaped_headers]
          frame = @frame_serializer.read_frame
          frame.should have_header("a\nspecial:head\\cer", " padded: and using\nspecial\\\\\\ncharacters ")
          frame.should have_body_encoding('UTF-8')
        end
        it "should properly read a frame with a body and no content-length" do
          @frame_io.string = @messages[:no_content_length]
          frame = @frame_serializer.read_frame
          frame.should have_body("hëllo!", "h\xC3\xABllo!", 'UTF-8')
          frame.should have_body_encoding('UTF-8')
        end
        it "should assume a binary charset if none is set and the content-type does not match text/*" do
          @frame_io.string = @messages[:non_text_content_type]
          frame = @frame_serializer.read_frame
          frame.should have_body_encoding('ASCII-8BIT')
        end
        it "should assume a binary charset if the content-type header is not specified" do
          @frame_io.string = @messages[:no_content_type]
          frame = @frame_serializer.read_frame
          frame.should have_body_encoding('ASCII-8BIT')
        end
        it "should set the value of a header to the first occurrence" do
          @frame_io.string = @messages[:repeated_headers]
          frame = @frame_serializer.read_frame
          frame.should have_header(:'repeated header', 'a value')
        end
        it "should raise a malformed frame error if the frame is not properly terminated" do
          @frame_io.string = @messages[:invalid_content_length]
          lambda { @frame_serializer.read_frame }.should raise_error(::Stomper::Errors::MalformedFrameError)
        end
        # While the spec suggests that all ":" chars be replaced with "\c", ActiveMQ 5.3.2 sends
        # a "session" header with a value that contains ":" chars.  So, we are NOT going to
        # freak out if we receive more than one ":" on a header line.
        it "should not raise an error if the frame contains a header value with a raw ':'" do
          @frame_io.string = @messages[:invalid_header_character]
          lambda { @frame_serializer.read_frame }.should_not raise_error
        end
        it "should raise an invalid header esacape sequence error if the frame contains a header with an invalid escape sequence" do
          @frame_io.string = @messages[:invalid_header_sequence]
          lambda { @frame_serializer.read_frame }.should raise_error(::Stomper::Errors::InvalidHeaderEscapeSequenceError)
        end
        it "should raise an malfored header error if the frame contains an incomplete header" do
          @frame_io.string = @messages[:malformed_header]
          lambda { @frame_serializer.read_frame }.should raise_error(::Stomper::Errors::MalformedHeaderError)
        end
        it "should raise an invalid header esacape sequence error if the frame contains a header with a dangling escape sequence" do
          @frame_io.string = @messages[:dangling_header_sequence]
          lambda { @frame_serializer.read_frame }.should raise_error(::Stomper::Errors::InvalidHeaderEscapeSequenceError)
        end
      end
    end
  end
end
