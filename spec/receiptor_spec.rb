require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe Receiptor do
    class MockConcreteReceipter
      include Stomper::Receiptor
    end

    before(:each) do
      @client = MockConcreteReceipter.new
    end
    
    describe "expected interface" do
    end

    describe "receipt handling" do
      before(:each) do
        @client.should_receive(:connected?).any_number_of_times.and_return(true)
        @client.should_receive(:send_without_receipt_handler).with('/queue/to','message body',a_kind_of(Hash)).at_least(:once).and_return(nil)
      end

      it "should dispatch a receipt when sent with a block" do
        @client.should_receive(:receive_without_receipt_dispatch).once.and_return(Stomper::Frames::Receipt.new({ :'receipt-id' => 'msg-0001' }, ''))
        receipt_processed = false
        @client.send('/queue/to', 'message body', :receipt => 'msg-0001') do |r|
          receipt_processed = true
        end
        @client.receipt_handlers.size.should == 1
        @client.receive_with_receipt_dispatch
        receipt_processed.should be_true
        @client.receipt_handlers.size.should == 0
      end
    end
  end
end