# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions
  describe Common do
    before(:each) do
      @common = mock("common", :version => '1.0')
      @common.extend Common
    end
    
    describe "Shared default interface" do
      it "should transmit an ABORT frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'transaction' => 'tx-1234'}, 'ABORT'))
        @common.abort('tx-1234')
      end
    
      it "should transmit a BEGIN frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'transaction' => 'tx-3124'}, 'BEGIN'))
        @common.begin('tx-3124')
      end
    
      it "should transmit a COMMIT frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'transaction' => 'tx-4321'}, 'COMMIT'))
        @common.commit('tx-4321')
      end
    
      it "should transmit a SEND frame with :send" do
        @common.should_receive(:transmit).with(stomper_frame('testing :send', {'destination' => '/queue/test_send'}, 'SEND'))
        @common.send('/queue/test_send', 'testing :send')
      end
    
      it "should transmit a SEND frame with :put" do
        @common.should_receive(:transmit).with(stomper_frame('testing :put', {'destination' => '/queue/test_put'}, 'SEND'))
        @common.put('/queue/test_put', 'testing :put')
      end
    
      it "should transmit a SUBSCRIBE frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'destination' => '/queue/test_subscribe'}, 'SUBSCRIBE'))
        @common.subscribe('/queue/test_subscribe')
      end
    
      it "should transmit an UNSUBSCRIBE frame for a given subscription ID" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'id' => 'subscription-1234'}, 'UNSUBSCRIBE'))
        @common.unsubscribe('subscription-1234')
      end
    
      it "should transmit an UNSUBSCRIBE frame for a given SUBSCRIBE frame" do
        subscribe = ::Stomper::Frame.new('SUBSCRIBE', { :id => 'id-in-frame-4321' })
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'id' => 'id-in-frame-4321'}, 'UNSUBSCRIBE'))
        @common.unsubscribe(subscribe)
      end
    
      it "should raise an error on :nack" do
        lambda { @common.nack("msg-001", "sub-001") }.should raise_error
      end
    
      it "should transmit an ACK for a message-id given MESSAGE frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-001'}, 'ACK'))
        @common.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-001' }, 'some body'))
      end
    
      it "should transmit an ACK for a message-id given a message-id" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-123'}, 'ACK'))
        @common.ack('msg-123')
      end
    
      it "should raise an error when the message-id cannot be inferred" do
        lambda { @common.ack('') }.should raise_error(ArgumentError)
        lambda { @common.ack(Stomper::Frame.new('MESSAGE', { :id => '' }, 'some body')) }.should raise_error(ArgumentError)
        lambda { @common.ack(nil) }.should raise_error(ArgumentError)
        lambda { @common.ack(Stomper::Frame.new('MESSAGE', {}, 'some body')) }.should raise_error(ArgumentError)
      end
    
      it "should return a new HeaderScope" do
        @common.with_headers({}).should be_an_instance_of(::Stomper::Scopes::HeaderScope)
      end
      it "should return a new TransactionScope" do
        @common.with_transaction.should be_an_instance_of(::Stomper::Scopes::TransactionScope)
      end
      it "should return a new ReceiptScope" do
        @common.with_receipt.should be_an_instance_of(::Stomper::Scopes::ReceiptScope)
      end
    end
    
    describe "1.1 Protocol Extensions" do
      before(:each) do
        @common.stub!(:version).and_return('1.1')
        Common.extend_by_protocol_version(@common, '1.1')
      end
      it "should include V1_1 module" do
        @common.should be_a_kind_of(Common::V1_1)
      end
      
      it "should transmit a NACK for a message-id and subscription given MESSAGE frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'NACK'))
        @common.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => 'sub-123' }, 'some body'))
      end
      it "should transmit a NACK for a message-id and subscription given MESSAGE frame w/o subscription and subscription-id" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'NACK'))
        @common.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => '' }, 'some body'), 'sub-123')
      end
      it "should transmit a NACK for a message-id and subscription given message-id and subscription-id" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'NACK'))
        @common.nack('msg-456', 'sub-123')
      end
      it "should raise an error when the subscription ID cannot be inferred" do
        lambda { @common.nack('msg-456') }.should raise_error(ArgumentError)
        lambda { @common.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body')) }.should raise_error(ArgumentError)
        lambda { @common.nack('msg-456', '') }.should raise_error(ArgumentError)
        lambda { @common.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '') }.should raise_error(ArgumentError)
        lambda { @common.nack('msg-456', { :subscription => ''}) }.should raise_error(ArgumentError)
        lambda { @common.nack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '', { :subscription => nil }) }.should raise_error(ArgumentError)
        lambda { @common.nack('msg-456', { :subscription => 'sub-123'}) }.should raise_error(ArgumentError)
      end
      it "should raise an error when the message-id cannot be inferred" do
        lambda { @common.nack('', 'sub-123') }.should raise_error(ArgumentError)
        lambda { @common.nack(Stomper::Frame.new('MESSAGE', { :id => '' }, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
        lambda { @common.nack(nil, 'sub-123') }.should raise_error(ArgumentError)
        lambda { @common.nack(Stomper::Frame.new('MESSAGE', {}, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
      end

      it "should transmit an ACK for a message-id and subscription given MESSAGE frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'ACK'))
        @common.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => 'sub-123' }, 'some body'))
      end    
      it "should transmit an ACK for a message-id and subscription given MESSAGE frame w/o subscription and subscription-id" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'ACK'))
        @common.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456', :subscription => '' }, 'some body'), 'sub-123')
      end
      it "should transmit an ACK for a message-id and subscription given message-id and subscription-id" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'message-id' => 'msg-456', 'subscription' => 'sub-123'}, 'ACK'))
        @common.ack('msg-456', 'sub-123')
      end
      it "should raise an error when the subscription ID cannot be inferred" do
        lambda { @common.ack('msg-456') }.should raise_error(ArgumentError)
        lambda { @common.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body')) }.should raise_error(ArgumentError)
        lambda { @common.ack('msg-456', '') }.should raise_error(ArgumentError)
        lambda { @common.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '') }.should raise_error(ArgumentError)
        lambda { @common.ack('msg-456', { :subscription => ''}) }.should raise_error(ArgumentError)
        lambda { @common.ack(Stomper::Frame.new('MESSAGE', { :id => 'msg-456' }, 'some body'), '', { :subscription => nil }) }.should raise_error(ArgumentError)
        lambda { @common.ack('msg-456', { :subscription => 'sub-123'}) }.should raise_error(ArgumentError)
      end
      it "should raise an error when the message-id cannot be inferred" do
        lambda { @common.ack('', 'sub-123') }.should raise_error(ArgumentError)
        lambda { @common.ack(Stomper::Frame.new('MESSAGE', { :id => '' }, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
        lambda { @common.ack(nil, 'sub-123') }.should raise_error(ArgumentError)
        lambda { @common.ack(Stomper::Frame.new('MESSAGE', {}, 'some body'), 'sub-123') }.should raise_error(ArgumentError)
        lambda { @common.ack('', { :'message-id' => 'msg-456', :subscription => 'sub-123'}) }.should raise_error(ArgumentError)
      end
    end
  end
end
