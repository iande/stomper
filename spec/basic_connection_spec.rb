require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'shared_connection_examples'))

module Stomper
  describe BasicConnection do
    it_should_behave_like "All Client Connections"

    before(:each) do
      @connection = BasicConnection.new("stomp:///")
    end
  end
end
