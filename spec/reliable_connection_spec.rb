require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'shared_connection_examples'))

module Stomper
  describe ReliableConnection do
    describe "shared behaviors" do
      before(:each) do
        @connection = ReliableConnection.new(BasicConnection.new("stomp:///"))
      end
      it_should_behave_like "All Client Connections"
    end

    describe "reliability" do
      before(:each) do
        @mock_basic_connection = mock("basic connection")
        Stomper::BasicConnection.stub!(:new).and_return(@mock_basic_connection)
        @mock_basic_connection.should_receive(:connect).with(no_args()).once.and_return(nil)
        @connection = ReliableConnection.new("stomp:///")
        @connection.reconnect_delay = 1
      end

      it "should reconnect when an IOError is raised during connect" do
        @mock_basic_connection.should_receive(:connect).with(no_args()).once.and_raise(IOError.new("mock io/error"))
        thread = Thread.new do
          # We sleep for a bit to ensure that the first receive is called
          # If the connection is behaving properly, the receive should fail quickly
          # and the connection should sleep for the specified reconnect delay
          # after which it will attempt to connect again.
          # Our sleep time is less than the reconnect delay so that by the time
          # the connection is "re-established", the non-failing receive is in place.
          sleep(0.5)
          @mock_basic_connection.should_receive(:connect).with(no_args()).once.and_return(nil)
        end
        @mock_basic_connection.should_receive(:receive).with(no_args()).once.and_return(nil)
        @connection.connect
        @connection.receive
      end


      it "should reconnect when an IOError is received during a transmit" do
        @send_frame = Stomper::Frames::Send.new("/queue/test/1", "message body")
        @mock_basic_connection.should_receive(:transmit).with(@send_frame).once.and_raise(IOError.new("mock io/error"))
        @mock_basic_connection.should_receive(:connect).with(no_args()).once.and_return(nil)
        @connection.transmit(@send_frame)
        @mock_basic_connection.should_receive(:transmit).with(@send_frame).once.and_return(nil)
        @connection.transmit(@send_frame)
      end

      it "should reconnect when an IOError is received during a receive" do
        @mock_basic_connection.should_receive(:receive).with(no_args()).once.and_raise(IOError.new("mock io/error"))
        @mock_basic_connection.should_receive(:connect).with(no_args()).once.and_return(nil)
        @connection.receive
        @mock_basic_connection.should_receive(:receive).with(no_args()).once.and_return(nil)
        @connection.receive
      end

      it "should not try to reconnect more than once within the specified timeout" do
        @mock_basic_connection.should_receive(:receive).with(no_args()).once.and_raise(IOError.new("mock io/error"))
        @mock_basic_connection.should_receive(:connect).with(no_args()).once.and_return(nil)
        thread = Thread.new do
          # We sleep for a bit to ensure that the first receive is called
          # If the connection is behaving properly, the receive should fail quickly
          # and the connection should sleep for the specified reconnect delay
          # after which it will attempt to connect again.
          # Our sleep time is less than the reconnect delay so that by the time
          # the connection is "re-established", the non-failing receive is in place.
          sleep(0.5)
          @mock_basic_connection.should_receive(:receive).with(no_args()).once.and_return(nil)
        end
        @connection.receive
        @connection.receive
        thread.join
      end
    end
  end
end
