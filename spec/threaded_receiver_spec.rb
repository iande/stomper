require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Stomper
  describe ThreadedReceiver do
    before(:each) do
      @connection = mock("connection")
      @connection.extend Stomper::ThreadedReceiver
    end
    
    describe "expected interface" do
      it "should provide a start method" do
        @connection.should respond_to(:start)
      end
      
      it "should provide a stop method" do
        @connection.should respond_to(:stop)
      end
    end
    
    describe "reading on a thread" do
      it "should start receiving when started, and stop when stopped." do
        @connection.should_receive(:connected?).once.and_return(false)
        @connection.should_receive(:connect).once.and_return(true)
        @connection.should_receive(:connected?).any_number_of_times.and_return(true)
        @connection.should_receive(:receive).at_least(:once).and_return(nil)
        @connection.start
        sleep(0.5)
        @connection.stop
        @connection.should_not_receive(:receive)
      end
    end
  end
end
