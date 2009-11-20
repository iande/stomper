require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe Subscription do
    before(:each) do
      @subscription = Subscription.new("/queue/test/1", 'subscription-1')
    end

    describe "basic expectations" do
      it "should be constructable from a parameter list, providing sensible defaults for omitted arguments" do
        @subscription.destination.should == "/queue/test/1"
        @subscription.ack.should == :auto
        @subscription.selector.should be_nil

        @subscription = Subscription.new("/queue/test/2", 'subscription-1', 'client', 'a > 3')
        @subscription.destination.should == "/queue/test/2"
        @subscription.ack.should == :client
        @subscription.selector.should == 'a > 3'
      end

      it "should be constructable from a hash, providing sensible defaults for omitted arguments" do
        @subscription = Subscription.new({ :destination => '/queue/test/2' })
        @subscription.destination.should == "/queue/test/2"
        @subscription.ack.should == :auto

        @subscription = Subscription.new({:destination => "/queue/test/3", :ack => :client, :id => 'subscription-3', :selector => 'b < 10' })
        @subscription.destination.should == "/queue/test/3"
        @subscription.ack.should == :client
        @subscription.id.should_not be_nil
        @subscription.selector.should == "b < 10"
      end

      # We do not insist that #id has to be equal to what was specified,
      # merely that it is not nil.
      it "should provide a meanginful ID when the subscription ID is specified" do
        @subscription.id.should_not be_nil
        @subscription.id.should_not be_empty
      end

      it "should provide a meaningful ID when the ack mode is not auto" do
        @client_ack_subscription = Subscription.new("/queue/test/1",nil,'client')
        @client_ack_subscription.id.should_not be_nil
      end

      it "should provide a meaningful ID when the selector is specified" do
        @selector_subscription = Subscription.new("/queue/test/1",nil,'auto',"a > 3.5")
        @selector_subscription.id.should_not be_nil
      end

      it "should provide a SUBSCRIBE frame" do
        @subscription.should respond_to(:to_subscribe)
        @frame = @subscription.to_subscribe
        @frame.destination.should == "/queue/test/1"
        @frame.id.should_not be_nil
        @frame.ack.should == "auto"
      end
    end

    describe "message matching" do
      it "should match a message without a subscription header only when the subscription is 'naive'" do
        @matching_subscription_1 = Subscription.new("/queue/test/1")
        @matching_subscription_2 = Subscription.new("/queue/test/1", nil, :auto)
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1'},"test message")
        @subscription.matches?(@message).should be_false
        @matching_subscription_1.matches?(@message).should be_true
        @matching_subscription_2.matches?(@message).should be_true
      end

      it "should be able to match against messages by destination" do
        @non_matching_subscription = Subscription.new("/queue/test/another")
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => @subscription.to_subscribe.id},"test message")
        @subscription.matches?(@message).should be_true
        @non_matching_subscription.matches?(@message).should be_false
      end

      it "should match messages only if the same destination and subscription" do
        @alternate_subscription = Subscription.new("/queue/test/1", 'subscription-2')
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => @subscription.to_subscribe.id},"test message")
        @subscription.matches?(@message).should be_true
        @alternate_subscription.matches?(@message).should be_false
      end

      it "should match messages by the subscription id if the message has a subscription" do
        @non_matching_subscription = Subscription.new("/queue/test/1")
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => 'subscription-1'},"test message")
        @subscription.matches?(@message).should be_true
        @non_matching_subscription.matches?(@message).should be_false
      end

      it "should not match messages with the same destination when its ack mode is not 'auto' and no subscription header was specified" do
        @non_matching_subscription = Subscription.new("/queue/test/1", nil, 'client')
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1'},"test message")
        @non_matching_subscription.matches?(@message).should be_false
      end

      it "should not match messages with the same destination when it has a selector and no subscription header was specified" do
        @non_matching_subscription = Subscription.new("/queue/test/1", nil, 'auto', 'rating > 3.0')
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1'},"test message")
        @non_matching_subscription.matches?(@message).should be_false
      end

      # Either insist that the #id method return something meaningful in non-trivial situations
      # as part of the expected behavior of the interface, or change this test!
      # We now insist on it, so this test is valid.
      it "should match messages when it has a selector and the subscription header was specified" do
        @non_matching_subscription = Subscription.new("/queue/test/1", nil, 'auto', 'rating > 3.0')
        # To test this without insisting that the #id field be equivalent to the subscribe frame's header
        # go this way:

        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => @non_matching_subscription.to_subscribe.id},"test message")
        @non_matching_subscription.matches?(@message).should be_true
      end
    end

    describe "message delivery" do
      it "should call its callback when an applicable message arrives for its destination" do
        called_back = false
        @subscription_with_block = Subscription.new("/queue/test/1", 'subscription-test') do |msg|
          called_back = (msg == @message)
        end
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => @subscription_with_block.to_subscribe.id},"test message")
        @subscription_with_block.perform(@message)
        called_back.should be_true
      end

      it "should not call its callback when given a message for a different destination" do
        called_back = false
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1'},"test message")
        @subscription_with_block = Subscription.new("/queue/test/another", 'subscription-test') do |msg|
          called_back = (msg == @message)
        end
        @subscription_with_block.perform(@message)
        called_back.should be_false
      end

      it "should call its callback when a message arrives for its subscription id" do
        called_back = false
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => 'subscription-test'},"test message")
        @subscription_with_block = Subscription.new("/queue/test/another", 'subscription-test') do |msg|
          called_back = (msg == @message)
        end
        @subscription_with_block.perform(@message)
        called_back.should be_true
      end

      it "should not call its callback when a message arrives for its subscription id, even on the same " do
        called_back = false
        @message = Stomper::Frames::Message.new({'destination' => '/queue/test/1', 'subscription' => 'subscription-not-test'},"test message")
        @subscription_with_block = Subscription.new("/queue/test/another", 'subscription-test') do |msg|
          called_back = (msg == @message)
        end
        @subscription_with_block.perform(@message)
        called_back.should be_false
      end
    end
  end
end