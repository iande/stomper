# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions::Protocols
  describe V1_0 do
    before(:each) do
      @protocol = mock("protocol")
      @protocol.extend ::Stomper::Extensions::Common
      @protocol.extend V1_0
    end
    
    it "should raise an error on :nack" do
      lambda { @protocol.nack("msg-001", "sub-001") }.should raise_error
    end
    
    it "should transmit an ACK for a message-id given MESSAGE frame" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-001'}, 'ACK'))
      @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-001' }, 'some body'))
    end
    
    it "should transmit an ACK for a message-id given a message-id" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-123'}, 'ACK'))
      @protocol.ack('msg-123')
    end
    
    it "should transmit an ACK for a message-id given headers w/ message-id" do
      #@protocol.ack
    end
    
    it "should raise an error when the message-id cannot be inferred" do
      lambda { @protocol.ack('') }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => '' }, 'some body')) }.should raise_error(ArgumentError)
      lambda { @protocol.ack(nil) }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', {}, 'some body')) }.should raise_error(ArgumentError)
    end
  end
  
  describe V1_1 do
    before(:each) do
      @protocol = mock("protocol")
      @protocol.extend ::Stomper::Extensions::Common
      @protocol.extend V1_1
    end
    
    it "should transmit a NACK for a message-id and subscription given MESSAGE frame" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'NACK'))
      @protocol.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => 'sub-123' }, 'some body'))
    end
    it "should transmit a NACK for a message-id and subscription given MESSAGE frame w/o subscription and subscription-id" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'NACK'))
      @protocol.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => '' }, 'some body'), 'sub-123')
    end
    it "should transmit a NACK for a message-id and subscription given message-id and subscription-id" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'NACK'))
      @protocol.nack('msg-456', 'sub-123')
    end
    it "should raise an error when the subscription ID cannot be inferred" do
      lambda { @protocol.nack('msg-456') }.should raise_error(ArgumentError)
      lambda { @protocol.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body')) }.should raise_error(ArgumentError)
      lambda { @protocol.nack('msg-456', '') }.should raise_error(ArgumentError)
      lambda { @protocol.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '') }.should raise_error(ArgumentError)
      lambda { @protocol.nack('msg-456', { :subscription => ''}) }.should raise_error(ArgumentError)
      lambda { @protocol.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '', { :subscription => nil }) }.should raise_error(ArgumentError)
      lambda { @protocol.nack('msg-456', { :subscription => 'sub-123'}) }.should raise_error(ArgumentError)
    end
    it "should raise an error when the message-id cannot be inferred" do
      lambda { @protocol.nack('', 'sub-123') }.should raise_error(ArgumentError)
      lambda { @protocol.nack(Stomper::Frame.new('MESSAGE', { :id => '' }, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
      lambda { @protocol.nack(nil, 'sub-123') }.should raise_error(ArgumentError)
      lambda { @protocol.nack(Stomper::Frame.new('MESSAGE', {}, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
    end
    
    it "should transmit an ACK for a message-id and subscription given MESSAGE frame" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'ACK'))
      @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => 'sub-123' }, 'some body'))
    end    
    it "should transmit an ACK for a message-id and subscription given MESSAGE frame w/o subscription and subscription-id" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'ACK'))
      @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => '' }, 'some body'), 'sub-123')
    end
    it "should transmit an ACK for a message-id and subscription given message-id and subscription-id" do
      @protocol.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'ACK'))
      @protocol.ack('msg-456', 'sub-123')
    end
    it "should raise an error when the subscription ID cannot be inferred" do
      lambda { @protocol.ack('msg-456') }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body')) }.should raise_error(ArgumentError)
      lambda { @protocol.ack('msg-456', '') }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '') }.should raise_error(ArgumentError)
      lambda { @protocol.ack('msg-456', { :subscription => ''}) }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '', { :subscription => nil }) }.should raise_error(ArgumentError)
      lambda { @protocol.ack('msg-456', { :subscription => 'sub-123'}) }.should raise_error(ArgumentError)
    end
    it "should raise an error when the message-id cannot be inferred" do
      lambda { @protocol.ack('', 'sub-123') }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => '' }, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
      lambda { @protocol.ack(nil, 'sub-123') }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', {}, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
      lambda { @protocol.ack('', { :'message-id' => 'msg-456', :subscription => 'sub-123'}) }.should raise_error(ArgumentError)
    end
  end
end
