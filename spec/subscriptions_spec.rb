require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe Subscriptions do
    before(:each) do
      @subscriptions = Subscriptions.new
    end

    describe "adding subscriptions" do
      it "should add a subscription given a subscription object" do
        @subscriptions << Subscription.new('/queue/test/3', 'subscription-3', nil, 'b < 10')
        @subscriptions.size.should == 1
        @subscriptions.first.destination.should == "/queue/test/3"
        @subscriptions.first.ack.should == :auto
        @subscriptions.first.selector.should == 'b < 10'
        @subscriptions.first.id.should_not be_nil
      end
    end

    describe "enumerable" do
      it "should provide an each method" do
        @subscriptions.should respond_to(:each)
      end
      it "should be enumerable" do
        @subscriptions.is_a?(Enumerable).should be_true
      end
    end

    describe "thread safe" do
      # How do you test this?
      it "should synchronize adding subscriptions" do
        @subscriptions << Subscription.new("/queue/test/1")
        @subscriptions << Subscription.new("/queue/test/2")
        @subscriptions << Subscription.new("/queue/test/3")
        Thread.new { sleep(0.25); @subscriptions << Subscription.new("/queue/test/4") }
        # In general, this next step should execute before the thread has a chance to
        # but the sleep in the map should mean that our thread gets woken up before
        # map finishes.  However, destinations should NEVER contain "/queue/test/4"
        # because map should be synchronized.
        destinations = @subscriptions.map { |sub| sleep(0.25); sub.destination }
        destinations.size.should == 3
        destinations.should == ['/queue/test/1', '/queue/test/2', '/queue/test/3']
        @subscriptions.size.should == 4
        @subscriptions.last.destination.should == "/queue/test/4"
      end

    end

    describe "message delivery" do
      it "should deliver messages to matching subscriptions" do
        received_1 = false
        received_2 = false
        received_3 = false
        @subscriptions << Subscription.new("/queue/test/1") { |msg| received_1 = true }
        @subscriptions << Subscription.new("/queue/test/1", 'subscription-2') { |msg| received_2 = true }
        @subscriptions << Subscription.new("/queue/test/2") { |msg| received_3 = true }
        #@message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => @non_matching_subscription.to_subscribe.id},"test message")
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1'},"test message")
        @subscriptions.perform(@message)
        received_1.should be_true
        received_2.should be_false
        received_3.should be_false
      end
    end

  end
end
