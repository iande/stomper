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