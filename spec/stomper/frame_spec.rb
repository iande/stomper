# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe Frame do
    before(:each) do
      @frame = Frame.new
    end
    
    it "should have a command attribute" do
      @frame.should respond_to(:command)
      @frame.should respond_to(:command=)
      @frame.command = 'command name'
      @frame.command.should == 'command name'
    end
    
    describe "headers" do
      it "should provide access to the headers through :headers" do
        @frame.headers.should be_a_kind_of(::Stomper::Headers)
      end
      
      it "should provide hash-like access to header assignment" do
        @frame['header name'] = 'header value'
        @frame['header name'].should == 'header value'
      end
    end
    
    describe "body" do
      before(:each) do
        @binary_encodings = ['ASCII-8BIT', 'US-ASCII', 'ASCII', 'BINARY', 'ANSI_X3.4-1968', '646']
        @other_encodings = ['UTF-8', 'ISO-8859-1']
      end
      
      it "should use the body's encoding as the charset for non-binary-ish encodings" do
        @frame.body = "a t\xEBst".force_encoding('ISO-8859-1')
        @frame.charset.should == 'ISO-8859-1'
        @frame.body = "a test".force_encoding('utf-8')
        @frame.charset.should == 'UTF-8'
      end
      
      it "should return a charset of US-ASCII for any binary-ish encoding" do
        @binary_encodings.each do |enc|
          @frame.body = "a test".encode(enc)
          @frame.charset.should == 'US-ASCII'
        end
      end
      
      it "should infer a content-type if none is specified based upon the encoding of the body" do
        @binary_encodings.each do |enc|
          @frame.body = "\x01\x02\x03\x04".encode(enc)
          @frame.content_type.should == 'application/octet-stream'
        end
        @other_encodings.each do |enc|
          @frame.body = 'a test'.encode(enc)
          @frame.content_type.should == 'text/plain'
        end
      end
      
      it "should use an explicit content type above all else" do
        @frame.content_type = 'application/pdf'
        (@binary_encodings + @other_encodings).each do |enc|
          @frame.body = "\x01\x02\x03\x04".encode(enc)
          @frame.content_type.should == 'application/pdf'
        end
        @frame[:'content-type'] = 'application/xml+xhtml'
        (@binary_encodings + @other_encodings).each do |enc|
          @frame.body = "\x01\x02\x03\x04".encode(enc)
          @frame.content_type.should == 'application/xml+xhtml'
        end
      end
      
      describe "content type and charset" do
        it "should provide a content type and charset based upon explicit settings" do
          @frame.content_type = 'application/pdf'
          @frame.body = "\x01\x02\x03\x04".encode('ISO-8859-1')
          @frame.content_type_and_charset.should == 'application/pdf;charset=ISO-8859-1'
        end

        it "should infer content type and charset from body encoding" do
          @frame.content_type = nil
          @frame.body = "\x01\x02\x03\x04".encode('ISO-8859-1')
          @frame.content_type_and_charset.should == 'text/plain;charset=ISO-8859-1'
        end

        it "should provide only the content type if charset cannot be determined" do
          @frame.content_type = 'some/content-type'
          @frame.body = nil
          @frame.content_type_and_charset.should == 'some/content-type'
        end

        it "should be nil when content-type is not explicitly set and cannot be inferred" do
          @frame.content_type = nil
          @frame.body = nil
          @frame.content_type_and_charset.should be_nil
        end
      end
    end
  end
end
