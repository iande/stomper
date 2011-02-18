# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe ReceiptManager do
    before(:each) do
      @connection = mock("connection")
    end
    
    it "should bind to the on_receipt event handler" do
      receipt = mock('receipt')
      @connection.should_receive(:on_receipt)
      @receipt_manager = ReceiptManager.new(@connection)
    end
    
    describe "usage" do
      before(:each) do
        @connection.extend ::Stomper::Extensions::Events
        @receipt_manager = ReceiptManager.new(@connection)
      end
      
      it "should add callbacks that are invoked by a matching receipt" do
        triggered = false
        @receipt_manager.add('1234', lambda { |r| triggered = true })
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '1234' }))
        triggered.should be_true
      end
      
      it "should not invoke callbacks that don't match the receipt" do
        triggered = false
        @receipt_manager.add('1234', lambda { |r| triggered = true })
        @receipt_manager.add('5678', lambda { |r| triggered = true })
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '12345' }))
        triggered.should be_false
      end
      
      it "should not invoke the same callback more than once" do
        triggered = 0
        @receipt_manager.add('1234', lambda { |r| triggered += 1 })
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '1234' }))
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '1234' }))
        triggered.should == 1
      end
      
      it "should allow a receipt handler to be registered within a callback" do
        triggered = [false, false]
        callback = lambda do |r|
          triggered[0] = true
          @receipt_manager.add('4567', lambda { |r| triggered[1] = true })
        end
        @receipt_manager.add('1234', callback)
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '1234' }))
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '4567' }))
        triggered.should == [true, true]
      end
      
      it "should allow a receipt handler to be registered within a callback in separate threads" do
        triggered = [false, false]
        started_r1 = false
        callback = lambda do |r|
          triggered[0] = true
          Thread.stop
        end
        @receipt_manager.add('1234', callback)
        r_1 = Thread.new(@connection) do |c|
          started_r1 = true
          Thread.stop
          c.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '1234' }))
        end
        r_2 = Thread.new(@connection) do |c|
          Thread.pass until triggered[0]
          @receipt_manager.add('4567', lambda { |r| triggered[1] = true })
          r_1.run
          c.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => '4567' }))
        end
        Thread.pass until started_r1
        r_1.run
        r_1.join
        r_2.join
        triggered.should == [true, true]
      end
    end
  end
end
