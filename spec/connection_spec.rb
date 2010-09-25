require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'shared_connection_examples'))

module Stomper
  describe Connection do
    describe "standard connection" do
      before(:each) do
        @connection = Connection.new("stomp:///")
      end
    
      it_should_behave_like "All Client Connections"
    end
    
    describe "ssl connection" do
      before(:each) do
        @connection = Connection.new("stomp+ssl:///")
      end
      
      it_should_behave_like "All Client Connections"
    end
  end
end
