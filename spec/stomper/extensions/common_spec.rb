# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions
  describe Common do
    before(:each) do
      @common = mock("common", :version => '1.0')
      @common.extend Common
      @subscription_manager = mock('subscription manager')
      @common.stub!(:subscription_manager).and_return(@subscription_manager)
    end
    
    describe "Shared default interface" do
      before(:each) do
        @common.stub!(:is_a?).with(::Stomper::Connection).and_return(true)
      end
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
    
      it "should transmit a SEND frame with :puts" do
        @common.should_receive(:transmit).with(stomper_frame('testing :puts', {'destination' => '/queue/test_puts'}, 'SEND'))
        @common.puts('/queue/test_puts', 'testing :puts')
      end
    
      it "should transmit a SUBSCRIBE frame" do
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'destination' => '/queue/test_subscribe'}, 'SUBSCRIBE'))
        @common.subscribe('/queue/test_subscribe')
      end
    
      it "should transmit an UNSUBSCRIBE frame for a given subscription ID" do
        @subscription_manager.should_receive(:subscribed_id?).with('subscription-1234').and_return(true)
        @common.should_receive(:transmit).with(stomper_frame_with_headers({'id' => 'subscription-1234'}, 'UNSUBSCRIBE'))
        @common.unsubscribe('subscription-1234')
      end
    
      it "should transmit an UNSUBSCRIBE frame for a given SUBSCRIBE frame" do
        @subscription_manager.should_receive(:subscribed_id?).with('id-in-frame-4321').and_return(true)
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
    
    describe "subscription handling" do
      it "should add a callback to the subscription manager on :subscribe" do
        # In this tests, we do not care about the particulars of the generated
        # frame. Our only interest is the interaction with the subscription
        # manager
        @common.stub!(:transmit).and_return { |f| f }
        @subscription_manager.should_receive(:add).with(stomper_frame_with_headers({}, 'SUBSCRIBE'), an_instance_of(Proc))
        @common.subscribe('/queue/test') { |m| true }
      end
      it "should unsubscribe by destination" do
        # As this invocation of unsubscribe will result in multiple UNSUBSCRIBE
        # frames being generated, we do care about the actual frames generated
        # as well.
        @common.should_receive(:transmit).with(stomper_frame_with_headers({:id => '1234'}, 'UNSUBSCRIBE'))
        @common.should_receive(:transmit).with(stomper_frame_with_headers({:id => '4567'}, 'UNSUBSCRIBE'))
        @subscription_manager.should_receive(:subscribed_id?).with('/queue/test').and_return(false)
        @subscription_manager.should_receive(:subscribed_destination?).with('/queue/test').and_return(true)
        @subscription_manager.should_receive(:ids_for_destination).with('/queue/test').and_return(['1234', '4567'])
        @common.unsubscribe("/queue/test")
      end
    end
    
    describe "SEND receipt handling" do
      it "should build a receipt scope when a block is passed to :send" do
        receipt_scope = mock('receipt scope')
        @common.should_receive(:with_receipt).and_return(receipt_scope)
        receipt_scope.should_receive(:transmit).with(stomper_frame('my message', { :destination => '/topic/testing' }, 'SEND'))
        @common.send('/topic/testing', 'my message') { |r| true }
      end
      
      it "should build a receipt scope when a block is passed to :puts" do
        receipt_scope = mock('receipt scope')
        @common.should_receive(:with_receipt).and_return(receipt_scope)
        receipt_scope.should_receive(:transmit).with(stomper_frame('my message', { :destination => '/topic/testing' }, 'SEND'))
        @common.puts('/topic/testing', 'my message') { |r| true }
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
