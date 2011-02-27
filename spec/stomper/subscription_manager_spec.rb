# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe SubscriptionManager do
    before(:each) do
      @connection = mock("connection")
    end
    
    it "should bind to the on_receipt event handler" do
      receipt = mock('receipt')
      @connection.should_receive(:on_message)
      @connection.should_receive(:on_unsubscribe)
      @connection.should_receive(:on_connection_closed)
      @subscription_manager = SubscriptionManager.new(@connection)
    end
    
    describe "usage" do
      before(:each) do
        @connection.extend ::Stomper::Extensions::Events
        @subscription_manager = SubscriptionManager.new(@connection)
        @subscribe_frame = ::Stomper::Frame.new('SUBSCRIBE', {:id => '1234', :destination => '/queue/testing'})
      end
      
      it "should correctly report subscriptoins" do
        @subscription_manager.add(@subscribe_frame, lambda { |m| true })
        @subscription_manager.subscribed.any? { |s| s[:id] == '1234' }.should be_true
        @subscription_manager.subscribed.any? { |s| s[:id] == '4321' }.should be_false
        @subscription_manager.remove('1234')
        @subscription_manager.subscribed.any? { |s| s[:id] == '1234' }.should be_false
      end
 
      it "should correctly report subscribed destinations" do
        @subscription_manager.add(@subscribe_frame, lambda { |m| true })
        @subscription_manager.subscribed.any? { |s| s[:destination] == '/queue/testing' }.should be_true
        @subscription_manager.subscribed.any? { |s| s[:destination] == '/queue/test' }.should be_false
        @subscription_manager.remove('/queue/testing')
        @subscription_manager.subscribed.any? { |s| s[:destination] == '/queue/testing' }.should be_false
      end
      
      it "should correctly map subscribed destinations to their IDs" do
        alt_subscribe_frame = ::Stomper::Frame.new('SUBSCRIBE', {:id => '4567', :destination => '/queue/test_further'})
        @subscription_manager.add(@subscribe_frame, lambda { |m| true })
        @subscription_manager.add(alt_subscribe_frame, lambda { |m| true })
        @subscription_manager.subscribed.map { |s| s[:id] }.should == ['1234', '4567']
        @subscription_manager.remove('/queue/testing')
        @subscription_manager.subscribed.map { |s| s[:id] }.should == ['4567']
        @subscription_manager.remove('/queue/test_further')
        @subscription_manager.subscribed.should be_empty
      end
      
      # it "should provide a set of subscriptions that were not unsubscribed before the connection was closed" do
      #   alt_subscribe_frame = ::Stomper::Frame.new('SUBSCRIBE', {:id => '4567', :destination => '/queue/test_further'})
      #   @subscription_manager.add(@subscribe_frame, lambda { |m| true })
      #   @subscription_manager.add(alt_subscribe_frame, lambda { |m| true })
      #   @subscription_manager.remove('1234')
      #   @connection.__send__(:trigger_event, :on_connection_closed, @connection)
      #   @subscription_manager.inactive_subscriptions.map { |s| s.id }.should == ['4567']
      # end
      
      it "should trigger subscriptions for MESSAGE frames with only a destination" do
        triggered = [0, 0]
        alt_subscribe_frame = ::Stomper::Frame.new('SUBSCRIBE', {:id => '4567', :destination => '/queue/testing'})
        @subscription_manager.add(@subscribe_frame, lambda { |m| triggered[0] += 1 })
        @subscription_manager.add(alt_subscribe_frame, lambda { |m| triggered[1] += 1 })
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :destination => '/queue/testing' }))
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :subscription => '4567' }))
        triggered.should == [1, 2]
      end
      
      it "should allow a subscription handler to be registered within a callback" do
        alt_subscribe_frame = ::Stomper::Frame.new('SUBSCRIBE', {:id => '4567', :destination => '/queue/testing'})
        triggered = [false, false]
        callback = lambda do |m|
          triggered[0] = true
          @subscription_manager.add(alt_subscribe_frame, lambda { |m| triggered[1] = true })
        end
        @subscription_manager.add(@subscribe_frame, callback)
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :subscription => '1234' }))
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :subscription => '4567' }))
        triggered.should == [true, true]
      end
      
      it "should allow a subscription to be removed within a callback" do
        triggered = 0
        callback = lambda do |m|
          triggered += 1
          @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('UNSUBSCRIBE', { :id => '1234' }))
        end
        @subscription_manager.add(@subscribe_frame, callback)
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :subscription => '1234' }))
        @connection.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :subscription => '1234' }))
        triggered.should == 1
      end
      
      it "should allow a subscription handler to be registered within a callback in separate threads" do
        alt_subscribe_frame = ::Stomper::Frame.new('SUBSCRIBE', {:id => '4567', :destination => '/queue/testing'})
        triggered = [false, false]
        started_r1 = false
        callback = lambda do |r|
          triggered[0] = true
          Thread.stop
        end
        @subscription_manager.add(@subscribe_frame, callback)
        r_1 = Thread.new(@connection) do |c|
          started_r1 = true
          Thread.stop
          c.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :subscription => '1234' }))
        end
        r_2 = Thread.new(@connection) do |c|
          Thread.pass until triggered[0]
          @subscription_manager.add(alt_subscribe_frame, lambda { |r| triggered[1] = true })
          r_1.run
          c.__send__(:trigger_received_frame, ::Stomper::Frame.new('MESSAGE', { :subscription => '4567' }))
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
