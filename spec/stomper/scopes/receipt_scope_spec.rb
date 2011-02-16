# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Scopes
  describe ReceiptScope do
    before(:each) do
      @connection = mock("connection", :is_a? => true, :version => '1.1')
      @connection.extend ::Stomper::Extensions::Events
      @scope = ReceiptScope.new(@connection, {})
    end
    
    it "should set up a handler on the connection when needed" do
      triggered = {}
      scope_block = lambda do |r|
        triggered[r[:'receipt-id']] = true
      end
      @scope.apply_to(scope_block)
      @connection.should_receive(:transmit).with(stomper_frame_with_headers({ :destination => '/queue/test', :receipt => 'receipt-1234' }, 'SEND'))
      @scope.send('/queue/test', 'body of message', { :receipt => 'receipt-1234' })
      @connection.should_receive(:transmit).with(stomper_frame_with_headers({ :destination => '/queue/test', :receipt => 'receipt-4567' }, 'SUBSCRIBE'))
      @scope.subscribe('/queue/test', { :receipt => 'receipt-4567' })
      
      @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => 'receipt-1234' }))
      @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => 'receipt-4567' }))
      triggered['receipt-1234'].should be_true
      triggered['receipt-4567'].should be_true
    end
    
    it "should set up receipt ids automatically when none are specified in the headers" do
      triggered = {}
      scope_block = lambda do |r|
        triggered[r[:'receipt-id']] = true
      end
      @connection.stub!(:transmit) { |f| f }
      @scope.apply_to(scope_block)
      frames = []
      frames << @scope.send('/queue/test', 'body of message', { :receipt => 'receipt-1234' })
      frames.last[:receipt].should == 'receipt-1234'
      frames << @scope.unsubscribe('/queue/test')
      frames.last[:receipt].should_not be_empty
      frames << @scope.ack('msg-1234', 'sub-5678')
      frames.last[:receipt].should_not be_empty
      frames.map { |r| r[:receipt] }.uniq.should == frames.map { |r| r[:receipt] }
      
      frames.each do |f|
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => f[:receipt] }))
        triggered[f[:receipt]].should be_true
      end
    end
    
    describe "thread safety" do
      # Everyone loves testing thread safety. Lots of comments in this test to clarify
      # what the hell I'm doing.
      it "should synchronize its list of receipt IDs, blocking new receipt generations until the handler is complete" do
        triggered = false
        scope_started = false
        firing_started = false
        scope_block = lambda do |r|
          scope_started = true
          Thread.stop
          # Receipt ID 'receipt-4567' should not be in the collection yet,
          # because @scope.send(...) should be blocked until this block completes
          @scope.instance_variable_get(:@receipt_ids).should_not include('receipt-4567')
          triggered = true
        end
        # Set up our transmission expectations
        @connection.should_receive(:transmit).with(stomper_frame_with_headers({ :destination => '/queue/test', :receipt => 'receipt-1234' }, 'SEND'))
        @connection.should_receive(:transmit).with(stomper_frame_with_headers({ :destination => '/queue/test', :receipt => 'receipt-4567' }, 'SEND'))
        # Register the callback
        @scope.apply_to(scope_block)
        
        # Generate our first entry in @scope's "@receipt_ids" instance variable
        @scope.send('/queue/test', 'body of message', { :receipt => 'receipt-1234' })
        # Trigger the event in a separate thread, as is likely to be the case
        # in real world use
        event_thread = Thread.new do
          @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('RECEIPT', { :'receipt-id' => 'receipt-1234' }))
        end
        # Prevent the "finish_firing_thread" from re-starting the "event_thread" too soon
        ready_to_trigger = false
        # This thread basically just waits a bit, and then tells "event_thread" to
        # finish evaluating "scope_block", thus creating a long-lasting hold
        # on the Mutex's lock within @scope.
        finish_firing_thread = Thread.new do
          firing_started = true
          Thread.pass until ready_to_trigger
          # Sleep a bit to ensure that @scope.send(...) has been called
          sleep 0.25
          event_thread.run
        end
        # Pass until both the 'finish_firing_thread' and 'event_thread' have started
        # and passed or stopped, respectively.
        Thread.pass until firing_started && scope_started
        # Set ready to trigger to true, otherwise scope_block will never complete its execution
        # and :send will not be able to acquire the mutex's lock.
        ready_to_trigger = true
        # At this point, scope_block has already begun execution, but has not yet
        # completed it, so the Mutex is locked, and :snd will block.
        @scope.send('/queue/test', 'other body', { :receipt => 'receipt-4567' })
        # Once we get here, scope_block has entirely completed, so triggered should
        # be true.
        triggered.should be_true
        # The triggering receipt-id 'receipt-1234' has been removed from the list.
        # Only 'receipt-4567' should remain.
        @scope.instance_variable_get(:@receipt_ids).should_not include('receipt-1234')
      end
    end
  end
end