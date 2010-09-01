require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe Client do
    class MockConcreteClient
      include Stomper::Client
    end

    before(:each) do
      @client = MockConcreteClient.new
    end
    
    describe "expected interface" do
      it "should provide a send method" do
        @client.should respond_to(:send)
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Send)).twice.and_return(nil)
        @client.send("/queue/to", "message body", {:additional => 'header'})
        @client.send("/queue/to", "message body")
      end
      it "should provide an ack method" do
        @client.should respond_to(:ack)
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Ack)).exactly(3).times.and_return(nil)
        @client.ack("message-id", {:additional => "header"})
        @client.ack("message-id")
        @client.ack(Stomper::Frames::Message.new({:'message-id' => 'msg-001'}, "body"))
      end
      it "should provide a begin method" do
        @client.should respond_to(:begin)
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Begin)).once.and_return(nil)
        @client.begin("tx-001")
      end
      it "should proivde an abort method" do
        @client.should respond_to(:abort)
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Abort)).once.and_return(nil)
        @client.abort("tx-001")
      end
      it "should provide a commit method" do
        @client.should respond_to(:commit)
        @client.should_receive(:transmit).with(an_instance_of(Stomper::Frames::Commit)).once.and_return(nil)
        @client.commit("tx-001")
      end
    end
  end
end