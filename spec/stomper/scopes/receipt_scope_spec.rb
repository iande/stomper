# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Scopes
  describe ReceiptScope do
    before(:each) do
      @receipt_manager = mock("receipt manager")
      @connection = mock("connection", :is_a? => true, :version => '1.1')
      @connection.stub!(:receipt_manager => @receipt_manager)
      @connection.stub!(:subscription_manager).and_return(mock('subscription manager', {
        :remove => ['/queue/test']
      }))
      @scope = ReceiptScope.new(@connection, {})
    end
    
    it "should add entries to the connection's receipt manager" do
      scope_block = lambda do |r|
      end
      @scope.apply_to(scope_block)
      
      @connection.should_receive(:transmit).with(stomper_frame_with_headers({ :destination => '/queue/test', :receipt => 'receipt-1234' }, 'SEND'))
      @receipt_manager.should_receive(:add).with('receipt-1234', an_instance_of(Proc)).once
      @scope.send('/queue/test', 'body of message', { :receipt => 'receipt-1234' })
      
      @connection.should_receive(:transmit).with(stomper_frame_with_headers({ :destination => '/queue/test', :receipt => 'receipt-4567' }, 'SUBSCRIBE'))
      @receipt_manager.should_receive(:add).with('receipt-4567', an_instance_of(Proc)).once
      @scope.subscribe('/queue/test', { :receipt => 'receipt-4567' })
    end
    
    it "should set up receipt ids automatically when none are specified in the headers" do
      scope_block = lambda do |r|
      end
      @connection.stub!(:transmit) { |f| f }
      @scope.apply_to(scope_block)
      
      frames = []
      @receipt_manager.should_receive(:add).with('receipt-1234', an_instance_of(Proc)).once
      frames << @scope.send('/queue/test', 'body of message', { :receipt => 'receipt-1234' })
      frames.last[:receipt].should == 'receipt-1234'
      
      @receipt_manager.should_receive(:add).with(an_instance_of(String), an_instance_of(Proc)).twice
      frames << @scope.unsubscribe('/queue/test')
      frames.last[:receipt].should_not be_empty
      
      frames << @scope.ack('msg-1234', 'sub-5678')
      frames.last[:receipt].should_not be_empty
      
      frames.map { |r| r[:receipt] }.uniq.should == frames.map { |r| r[:receipt] }
    end
  end
end