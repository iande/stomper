# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions::Protocols
  describe V1_0::Acking do
    before(:each) do
      @protocol = mock("protocol")
      @protocol.extend ::Stomper::Extensions::Common
      @protocol.extend V1_0::Acking
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
    
    it "should raise an error when the message-id cannot be inferred" do
      lambda { @protocol.ack('') }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', { :id => '' }, 'some body')) }.should raise_error(ArgumentError)
      lambda { @protocol.ack(nil) }.should raise_error(ArgumentError)
      lambda { @protocol.ack(Stomper::Frame.new('MESSAGE', {}, 'some body')) }.should raise_error(ArgumentError)
    end
  end
  
  describe V1_1::Acking do
    before(:each) do
      @protocol = mock("protocol")
      @protocol.extend ::Stomper::Extensions::Common
      @protocol.extend V1_1::Acking
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
  
  describe V1_0::Heartbeating do
    before(:each) do
      @heartbeats = mock('heartbeats')
      @heartbeats.extend V1_0::Heartbeating
    end
    
    it "should be dead? when it is not alive?" do
      @heartbeats.stub(:alive? => true)
      @heartbeats.dead?.should be_false
      
      @heartbeats.stub(:alive? => false)
      @heartbeats.dead?.should be_true
    end
    
    it "should do nothing when :beat is called" do
      @heartbeats.beat.should be_nil
    end
    
    it "should be alive if the connection is connected?" do
      @heartbeats.should_receive(:connected?).and_return(true)
      @heartbeats.alive?.should be_true
      @heartbeats.should_receive(:connected?).and_return(false)
      @heartbeats.alive?.should be_false
    end
  end
  
  describe V1_1::Heartbeating do
    before(:each) do
      @heartbeats = mock('heartbeats')
      @heartbeats.extend V1_1::Heartbeating
    end
    
    it "should transmit a heartbeat frame through :beat" do
      @heartbeats.should_receive(:transmit).with(stomper_heartbeat_frame)
      @heartbeats.beat
    end
    
    it "should be alive if client and broker are alive and connected" do
      @heartbeats.stub(:client_alive? => true, :broker_alive? => true, :connected? => true)
      @heartbeats.alive?.should be_true
      @heartbeats.stub(:connected? => false)
      @heartbeats.alive?.should be_false
    end
    
    
    it "should be dead if connected and broker is alive but client is not" do
      @heartbeats.stub(:client_alive? => false, :broker_alive? => true, :connected? => true)
      @heartbeats.alive?.should be_false
      @heartbeats.stub(:client_alive? => true)
      @heartbeats.alive?.should be_true
    end
    
    it "should be dead if connected and client is alive but broker is not" do
      @heartbeats.stub(:client_alive? => true, :broker_alive? => false, :connected? => true)
      @heartbeats.alive?.should be_false
      @heartbeats.stub(:broker_alive? => true)
      @heartbeats.alive?.should be_true
    end
    
    it "should have a living client if client beats are disabled" do
      @heartbeats.stub(:heartbeating => [0, 10], :connected? => true)
      @heartbeats.client_alive?.should be_true
    end
    
    it "should have a living broker if broker beats are disabled" do
      @heartbeats.stub(:heartbeating => [10, 0], :connected? => true)
      @heartbeats.broker_alive?.should be_true
    end
    
    it "should have a living client if beating is enabled and transmitted within a marin of error" do
      @heartbeats.stub(:heartbeating => [1_000, 0], :connected? => true)
      @heartbeats.stub(:duration_since_transmitted => 50)
      @heartbeats.client_alive?.should be_true
      @heartbeats.stub(:duration_since_transmitted => 1_000)
      @heartbeats.client_alive?.should be_true
      @heartbeats.stub(:duration_since_transmitted => 1_100)
      @heartbeats.client_alive?.should be_true
      @heartbeats.stub(:duration_since_transmitted => 1_200)
      @heartbeats.client_alive?.should be_false
    end
    
    it "should have a living broker if beating is enabled and received within a marin of error" do
      @heartbeats.stub(:heartbeating => [0, 5_000], :connected? => true)
      @heartbeats.stub(:duration_since_received => 100)
      @heartbeats.broker_alive?.should be_true
      @heartbeats.stub(:duration_since_received => 5_000)
      @heartbeats.broker_alive?.should be_true
      @heartbeats.stub(:duration_since_received => 5_500)
      @heartbeats.broker_alive?.should be_true
      @heartbeats.stub(:duration_since_received => 5_600)
      @heartbeats.broker_alive?.should be_false
    end
  end
end
