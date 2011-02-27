# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Scopes
  describe TransactionScope do
    before(:each) do
      @connection = mock("connection", :is_a? => true, :version => '1.1')
      @headers = { :transaction => 'tx-1234' }
      @connection.stub!(:subscription_manager).and_return(mock('subscription manager', {
        :remove => ['no-real-destination']
      }))
      @scope = TransactionScope.new(@connection, @headers)
      @connection.should_receive(:transmit).at_most(:once).with(stomper_frame_with_headers(@headers, 'BEGIN'))
    end
    
    it "should generate a transaction ID if one was not provided" do
      auto_scope = TransactionScope.new(@connection, {})
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
end
