require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe SubscriberInterface do
    class MockConcreteSubscriber
      include Stomper::SubscriberInterface
    end

    before(:each) do
      @client = MockConcreteSubscriber.new
    end
    
    describe "expected interface" do
      it "should provide a subscribe method" do
        @client.should respond_to(:subscribe)
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Subscribe)).twice.and_return(nil)
        @client.subscribe("/queue/to", {:additional => 'header'})
        @client.subscribe("/queue/to")
      end
      it "should provide an unsubscribe method" do
        @client.should respond_to(:unsubscribe)
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Subscribe)).twice.and_return(nil)
        @client.subscribe("/queue/to", {:id => 'subscription-id'})
        @client.subscribe("/queue/to")
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Unsubscribe)).twice.and_return(nil)
        @client.unsubscribe("/queue/to", 'subscription-id')
        @client.unsubscribe("/queue/to")
      end
    end

    describe "subscribing to queue" do
      before(:each) do
        @message_sent = Stomper::Frames::Message.new({:destination => "/queue/test"}, "test message")
        @client.should_receive(:connected?).any_number_of_times.and_return(true)
        @client.should_receive(:transmit).with(a_kind_of(Stomper::Frames::ClientFrame)).at_least(:once).and_return(nil)
        @client.should_receive(:receive).any_number_of_times.and_return(@message_sent)
      end

      it "should subscribe to a destination with a block" do
        @message_received = nil
        @client.subscribe("/queue/test") do |msg|
          @message_received = msg
        end
        @client.receive
        @message_received.should == @message_sent
      end

      it "should not unsubscribe from all destinations when a subscription id is provided" do
        @client.subscribe("/queue/test", { :id => 'subscription-1' }) do |msg|
          @message_received = msg
        end
        @client.subscribe("/queue/test") do |msg|
          @message_received = msg
        end
        @client.subscribe("/queue/test", :id => 'subscription-2') do |msg|
          @message_received = msg
        end
        @client.unsubscribe("/queue/test", 'subscription-1')
        @client.subscriptions.size.should == 2
      end

      it "should not unsubscribe from non-naive subscriptions when only a destination is supplied" do
        @client.subscribe("/queue/test", { :id => 'subscription-1' }) do |msg|
          @message_received = msg
        end
        @client.subscribe("/queue/test") do |msg|
          @message_received = msg
        end
        @client.subscribe("/queue/test") do |msg|
          @message_received = msg
        end
        @client.unsubscribe("/queue/test")
        @client.subscriptions.size.should == 1
      end
    end
  end
end