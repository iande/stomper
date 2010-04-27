require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe Client do
    before(:each) do
      # For the client, we want to mock the underlying connection
      @mock_connection = mock("connection")
      @mock_connection.should_receive(:disconnect).with(no_args()).at_most(:once).and_return(nil)
      Stomper::Connection.stub!(:new).and_return(@mock_connection)
      @client = Client.new("stomp:///")
    end
    
    describe "expected interface" do
      it "should provide a send method" do
        @client.should respond_to(:send)
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Send)).twice.and_return(nil)
        @client.send("/queue/to", "message body", {:additional => 'header'})
        @client.send("/queue/to", "message body")
      end
      it "should provide a subscribe method" do
        @client.should respond_to(:subscribe)
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Subscribe)).twice.and_return(nil)
        @client.subscribe("/queue/to", {:additional => 'header'})
        @client.subscribe("/queue/to")
      end
      it "should provide an unsubscribe method" do
        @client.should respond_to(:unsubscribe)
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Subscribe)).twice.and_return(nil)
        @client.subscribe("/queue/to", {:id => 'subscription-id'})
        @client.subscribe("/queue/to")
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Unsubscribe)).twice.and_return(nil)
        @client.unsubscribe("/queue/to", 'subscription-id')
        @client.unsubscribe("/queue/to")
      end
      it "should provide an ack method" do
        @client.should respond_to(:ack)
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Ack)).exactly(3).times.and_return(nil)
        @client.ack("message-id", {:additional => "header"})
        @client.ack("message-id")
        @client.ack(Stomper::Frames::Message.new({:'message-id' => 'msg-001'}, "body"))
      end
      it "should provide a begin method" do
        @client.should respond_to(:begin)
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Begin)).once.and_return(nil)
        @client.begin("tx-001")
      end
      it "should proivde an abort method" do
        @client.should respond_to(:abort)
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Abort)).once.and_return(nil)
        @client.abort("tx-001")
      end
      it "should provide a commit method" do
        @client.should respond_to(:commit)
        @mock_connection.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Commit)).once.and_return(nil)
        @client.commit("tx-001")
      end
      it "should provide a recieve method" do
        @client.should respond_to(:receive)
      end
      it "should provide a disconnect method" do
        @client.should respond_to(:disconnect)
      end
      it "should provide a close method" do
        @client.should respond_to(:close)
      end
      it "should provide a connectivity test" do
        @client.should respond_to(:connected?)
      end
      it "should provide a connect method" do
        @client.should respond_to(:connect)
      end
    end

    describe "threaded receiver" do
      it "should respond to start and stop" do
        @client.should respond_to(:start)
        @client.should respond_to(:stop)
        @client.should respond_to(:receiving?)
      end
      it "should only be receiving when it is started" do
        @mock_connection.stub!(:receive).and_return(nil)
        @mock_connection.should_receive(:connected?).any_number_of_times.and_return(true)
        @client.receiving?.should be_false
        @client.start
        @client.receiving?.should be_true
        @client.stop
        @client.receiving?.should be_false
      end
      it "should allow for a blocking threaded receiver" do
        @mock_connection.should_receive(:receive).with(true).at_least(:once).and_return(nil)
        @mock_connection.should_receive(:connected?).any_number_of_times.and_return(true)
        @client.receiving?.should be_false
        @client.start(:block => true)
        @client.receiving?.should be_true
        @client.stop
        @client.receiving?.should be_false
      end

    end

    describe "subscribing to queue" do
      before(:each) do
        @message_sent = Stomper::Frames::Message.new({:destination => "/queue/test"}, "test message")
        @mock_connection.should_receive(:connected?).any_number_of_times.and_return(true)
        @mock_connection.should_receive(:transmit).with(a_kind_of(Stomper::Frames::ClientFrame)).at_least(:once).and_return(nil)
        @mock_connection.should_receive(:receive).any_number_of_times.and_return(@message_sent)
      end

      it "should subscribe to a destination with a block" do
        wait_for_message = true
        @message_received = nil
        @client.start
        @client.subscribe("/queue/test") do |msg|
          @message_received = msg
          wait_for_message = false
        end
        true while wait_for_message
        @client.stop
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

      # Due to the receiver running in a separate thread, this may not be correct?
      it "should unsubscribe from a destination and receive no more messages" do
        @mutex = Mutex.new
        @last_message_received = nil
        @client.start
        @client.subscribe("/queue/test") do |msg|
          @last_message_received = Time.now
        end
        true until @last_message_received
        @client.unsubscribe("/queue/test")
        @unsubscribed_at = Time.now
        @client.stop
        (@last_message_received < @unsubscribed_at).should be_true
      end
    end

    describe "transactions" do
      before(:each) do
        @mock_connection.should_receive(:transmit).with(a_kind_of(Stomper::Frames::ClientFrame)).at_least(:once).and_return(nil)
      end

      it "should provide a transaction method that generates a new Transaction" do
        @evaluated = false
        @client.transaction do |t|
          @evaluated = true
        end
        @evaluated.should be_true
      end
    end
  end
end