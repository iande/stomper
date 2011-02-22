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
      
      it "should provide a convenience method for content-type" do
        @frame[:'content-type'] = 'text/plain; charset=UTF-8; param=val'
        @frame.content_type.should == 'text/plain'
        
        @frame[:'content-type'] = nil
        @frame.content_type.should == ''
      end
    end
  end
end
