# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions
  describe Scoping do
    before(:each) do
      @scoping = mock("scoping", :is_a? => true, :version => '1.1')
      @scoping.extend Scoping
    end

    it "should return a new HeaderScope" do
      @scoping.with_headers({}).should be_an_instance_of(Scoping::HeaderScope)
    end
    it "should return a new TransactionScope" do
      @scoping.with_transaction.should be_an_instance_of(Scoping::TransactionScope)
    end
    it "should return a new ReceiptScope" do
      @scoping.with_receipt.should be_an_instance_of(Scoping::ReceiptScope)
    end
  end
  
  describe Scoping::HeaderScope do
    before(:each) do
      @connection = mock("connection", :is_a? => true, :version => '1.1')
      @headers = { :global_1 => 'turbo', 'global_2' => 'is me', :persistent => true }
      @scope = Scoping::HeaderScope.new(@connection, @headers)
    end
    
    it "should apply the headers to any frame generated on its Common interface" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'BEGIN'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'UNSUBSCRIBE'))
      @scope.send("/queue/test", "body of message", { :local_1 => 'my header' })
      @scope.begin("transaction-1234", { :local_2 => 'other header'})
      @scope.unsubscribe('no-real-destination')
    end
    
    it "should evaluate a proc through itself if one is provided" do
      scope_block = lambda do |h|
        h.abort('transaction-1234')
        h.subscribe('/queue/test')
        h.commit('transaction-1234')
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ABORT'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SUBSCRIBE'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'COMMIT'))
      @scope.apply_to(scope_block)
    end
    
    it "should override its headers with those passed through the frame methods" do
      overridden_headers = @headers.merge(:persistent => 'false')
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(overridden_headers, 'SEND'))
      @scope.send('/queue/test', 'body of message', { :persistent => false })
    end
    
    describe "nested header scopes" do
      before(:each) do
        @child_headers = { :child_1 => 1985, 'persistent' => false }
        @child_scope = Scoping::HeaderScope.new(@scope, @child_headers)
        @merged_headers = { :global_1 => 'turbo', :global_2 => 'is me', :persistent => false, :child_1 => 1985 }
      end
      it "should include headers from the parent scope" do
        @connection.should_receive(:transmit).with(stomper_frame_with_headers(@merged_headers, 'SEND'))
        @child_scope.send('/queue/test', 'body of message')
      end
    end
  end
  
  describe Scoping::TransactionScope do
    before(:each) do
      @connection = mock("connection", :is_a? => true, :version => '1.1')
      @headers = { :transaction => 'tx-1234' }
      @scope = Scoping::TransactionScope.new(@connection, @headers)
      @connection.should_receive(:transmit).at_most(:once).with(stomper_frame_with_headers(@headers, 'BEGIN'))
    end
    
    it "should generate a transaction ID if one was not provided" do
      auto_scope = Scoping::TransactionScope.new(@connection, {})
      auto_scope_name = auto_scope.transaction
      auto_scope_name.should_not be_empty
      @connection.should_receive(:transmit).with(stomper_frame_with_headers({:transaction => auto_scope_name}, 'BEGIN'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers({:transaction => auto_scope_name}, 'SEND'))
      auto_scope.send('/queue/test', 'body of message')
    end
    
    it "should apply a transaction header to SEND" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @scope.send('/queue/test', 'body of message')
    end
    
    it "should apply a transaction header to ACK" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ACK'))
      @scope.ack('msg-001', 'sub-001')
    end
    
    it "should apply a transaction header to COMMIT" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'COMMIT'))
      @scope.commit
    end
    
    it "should apply a transaction header to ABORT" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ABORT'))
      @scope.abort
    end
    
    it "should apply a transaction header to COMMIT" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'COMMIT'))
      @scope.commit
    end
    
    it "should apply a transaction header to NACK" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'NACK'))
      @scope.nack('msg-001', 'sub-001')
    end
    
    it "should not apply a transaction header to SUBSCRIBE, UNSUBSCRIBE" do
      @connection.stub!(:transmit).and_return { |f| f }
      subscribe = @scope.subscribe('/queue/test')
      unsubscribe = @scope.unsubscribe(subscribe)
      subscribe.headers.has?(:transaction).should be_false
      unsubscribe.headers.has?(:transaction).should be_false
    end
    
    it "should raise an error when beginning a transaction that has already begun" do
      @connection.stub!(:transmit).and_return { |f| f }
      @scope.send('/queue/test', 'body of message')
      lambda { @scope.begin }.should raise_error
    end
    
    it "should raise an error when aborting a transaction that has already aborted" do
      @connection.stub!(:transmit).and_return { |f| f }
      @scope.abort
      lambda { @scope.abort }.should raise_error
    end
    
    it "should raise an error when aborting a transaction that has already committed" do
      @connection.stub!(:transmit).and_return { |f| f }
      @scope.commit
      lambda { @scope.abort }.should raise_error
    end
    
    it "should raise an error when committing a transaction that has already aborted" do
      @connection.stub!(:transmit).and_return { |f| f }
      @scope.abort
      lambda { @scope.commit }.should raise_error
    end
    
    it "should raise an error when committing a transaction that has already committed" do
      @connection.stub!(:transmit).and_return { |f| f }
      @scope.commit
      lambda { @scope.commit }.should raise_error
    end
    
    it "should evaluate a block as a transaction and commit it if the block does not raise an error" do
      scope_block = lambda do |t|
        t.send('/queue/test', 'body of message')
        t.ack('msg-1234', 'sub-4321')
        t.nack('msg-5678', 'sub-8765')
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ACK'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'NACK'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'COMMIT'))
      @scope.apply_to(scope_block)
    end
    
    it "should evaluate a block as a transaction but do nothing if the transaction never started" do
      scope_block = lambda do |t|
      end
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'BEGIN'))
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'COMMIT'))
      @scope.apply_to(scope_block)
    end
    
    it "should evaluate a block as a transaction and abort the transaction and raise an exception if an exception is raised" do
      scope_block = lambda do |t|
        t.send('/queue/test', 'body of message')
        t.ack('msg-1234', 'sub-4321')
        raise "Time to abort!"
        t.nack('msg-5678', 'sub-8765')
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ACK'))
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'NACK'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ABORT'))
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'COMMIT'))
      lambda { @scope.apply_to(scope_block) }.should raise_error('Time to abort!')
    end
    
    it "should not commit a transaction block that was manually aborted" do
      scope_block = lambda do |t|
        t.send('/queue/test', 'body of message')
        t.ack('msg-1234', 'sub-4321')
        t.abort
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ACK'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ABORT'))
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'COMMIT'))
      lambda { @scope.apply_to(scope_block) }.should_not raise_error
    end
    
    it "should not re-commit a transaction block that was manually committed" do
      scope_block = lambda do |t|
        t.send('/queue/test', 'body of message')
        t.ack('msg-1234', 'sub-4321')
        t.commit
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ACK'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'COMMIT'))
      lambda { @scope.apply_to(scope_block) }.should_not raise_error
    end
    
    it "should raise an error if further transactionable frames are sent after the transaction has been aborted" do
      scope_block = lambda do |t|
        t.send('/queue/test', 'body of message')
        t.ack('msg-1234', 'sub-4321')
        t.abort
        t.nack('msg-5678', 'sub-8765')
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ACK'))
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'NACK'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ABORT'))
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'COMMIT'))
      lambda { @scope.apply_to(scope_block) }.should raise_error(::Stomper::Errors::TransactionFinalizedError)
    end
    
    it "should raise an error if further transactionable frames are sent after the transaction has been committed" do
      scope_block = lambda do |t|
        t.send('/queue/test', 'body of message')
        t.ack('msg-1234', 'sub-4321')
        t.commit
        t.nack('msg-5678', 'sub-8765')
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ACK'))
      @connection.should_not_receive(:transmit).with(stomper_frame(nil, {}, 'NACK'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'COMMIT'))
      lambda { @scope.apply_to(scope_block) }.should raise_error(::Stomper::Errors::TransactionFinalizedError)
    end
  end
  
  describe Scoping::ReceiptScope do
    before(:each) do
      @connection = mock("connection", :is_a? => true, :version => '1.1')
      @connection.extend ::Stomper::Extensions::Events
      @scope = Scoping::ReceiptScope.new(@connection, {})
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
