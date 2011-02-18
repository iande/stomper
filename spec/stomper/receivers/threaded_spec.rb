# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Receivers
  describe Threaded do
    before(:each) do
      @connection = mock("connection")
      @receiver = Threaded.new(@connection)
      @receive_called = false
    end
    
    def mock_receive_call
      @connection.stub!(:receive).and_return(true)
    end
    
    def expect_receive_call
      @connection.should_receive(:receive).at_least(:once).and_return do
        @receive_called = true
      end
    end
    
    def wait_until_receive_called(reset=true)
      @receive_called = false if reset
      Thread.pass until @receive_called
    end
    
    it "should start running when :start is called, creating a new thread" do
      expect_receive_call
      initial_threads = Thread.list.size
      @receiver.start
      wait_until_receive_called
      @receiver.running?.should be_true
      Thread.list.size.should == (initial_threads + 1)
      @receiver.stop
    end
    
    it "should stop running when :stop is called, joining its run thread" do
      mock_receive_call
      initial_threads = Thread.list.size
      @receiver.start
      @receiver.stop
      @receiver.running?.should be_false
      Thread.list.size.should == initial_threads
    end
    
    it "should receive frames from its connection until it is stopped" do
      thread_check = false
      @connection.should_receive(:receive).twice.and_return do
        Thread.pass until thread_check
        thread_check = false
      end
      @receiver.start
      thread_check = true
      Thread.pass while thread_check
      thread_check = true
      @receiver.stop
    end
    
    it "should not create more than one thread if :start is invoked repeatedly" do
      expect_receive_call
      initial_threads = Thread.list.size
      running_threads = initial_threads+1
      
      @receiver.start
      wait_until_receive_called
      Thread.list.size.should == running_threads
      
      @receiver.start
      wait_until_receive_called
      Thread.list.size.should == running_threads
      
      @receiver.start
      wait_until_receive_called
      Thread.list.size.should == running_threads
      
      @receiver.stop
      Thread.list.size.should == initial_threads
    end
    
    it "should not raise an error if :stop is invoked repeatedly" do
      expect_receive_call
      @receiver.start
      wait_until_receive_called

      @receiver.stop
      lambda { @receiver.stop }.should_not raise_error
      lambda { @receiver.stop }.should_not raise_error
    end
    
    it "should stop itself if receiving a frame raises any error" do
      @connection.should_receive(:receive).and_raise('stopping the receiver')
      @receiver.start
      Thread.pass while @receiver.running?
      lambda { @receiver.stop }.should raise_error('stopping the receiver')
    end
    
    it "should propegate an IOError if the connection is still connected" do
      @connection.should_receive(:connected?).and_return(true)
      @connection.should_receive(:receive).and_raise(IOError.new('stopping the receiver'))
      @receiver.start
      Thread.pass while @receiver.running?
      lambda { @receiver.stop }.should raise_error(IOError)
    end
    
    it "should not propegate an IOError if the connection is not connected" do
      @connection.should_receive(:connected?).and_return(false)
      @connection.should_receive(:receive).and_raise(IOError.new('stopping the receiver'))
      @receiver.start
      Thread.pass while @receiver.running?
      lambda { @receiver.stop }.should_not raise_error
    end
  end
end
