require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe Transactor do
    class MockConcreteTransactor
      include Stomper::Transactor
    end

    before(:each) do
      @client = MockConcreteTransactor.new
    end
    
    describe "expected interface" do
      it "should provide a transaction method" do
        @client.should respond_to(:transaction)
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

    describe "transactions" do
      it "should provide a transaction method that generates a new Transaction" do
        @client.should_receive(:begin)
        @client.should_receive(:commit)
        @evaluated = false
        @client.transaction do |t|
          @evaluated = true
        end
        @evaluated.should be_true
      end
    end
  end
end