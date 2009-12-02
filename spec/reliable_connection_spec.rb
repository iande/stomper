require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'shared_connection_examples'))

module Stomper
  describe ReliableConnection do
    describe "shared behaviors" do
      before(:each) do
        @connection = ReliableConnection.new("stomp:///")
      end
      it_should_behave_like "All Client Connections"
    end

    describe "reliability" do
      # This is really awful, though appropriately named.  I REALLY should
      # favor composition over inheritance, and here is further proof of that.
      # My options here were to mock and stub all of TCP connection so I could
      # raise IO Errors in a controlled and testable way, or to slap a mock
      # module in the inheritance chain that you could stub.
      # The former would result in writing a lot of low-level crap that I don't
      # really care about, since I want to test the exception handling at a
      # much higher level.  If I tried to tell a TCPSocket mock exactly how many
      # times I should expect a read or write statement (or any of the lower level
      # methods those methods call) I might as well be writing a test suite for
      # basic networking.  So, here we are, splicing in a module into the
      # inheritance chain between ReliableConnection and BasicConnection, and
      # stubbing the methods that would have otherwise percolated up from
      # Reliable to Basic.  I want to get back to composition with delegation
      # and decoration, but decogator hasn't been tested well enough, so
      # this crap will stay for a little while.
      module EpicImplementationFail; end
      class ::Stomper::ReliableConnection; include EpicImplementationFail; end

      before(:each) do
        EpicImplementationFail.stub!(:connect).with(no_args()).once.and_return(nil)
        EpicImplementationFail.stub!(:connected?).with(no_args()).once.and_return(false)
        @connection = ReliableConnection.new("stomp:///")
        @connection.reconnect_delay = 0.1
      end

      it "should reconnect when an IOError is raised during connect" do
        EpicImplementationFail.stub!(:connect).with(no_args()).once.and_raise(IOError.new("mock io/error"))
        thread = Thread.new do
          # We sleep for a bit to ensure that the first receive is called
          # If the connection is behaving properly, the receive should fail quickly
          # and the connection should sleep for the specified reconnect delay
          # after which it will attempt to connect again.
          # Our sleep time is less than the reconnect delay so that by the time
          # the connection is "re-established", the non-failing receive is in place.
          sleep(0.05)
          EpicImplementationFail.stub!(:connect).with(no_args()).once.and_return(nil)
        end
        EpicImplementationFail.stub!(:receive).with(no_args()).once.and_return(nil)
        @connection.connect
        @connection.receive
      end

      it "should reconnect when an IOError is received during a transmit" do
        @send_frame = Stomper::Frames::Send.new("/queue/test/1", "message body")
        EpicImplementationFail.stub!(:transmit).with(@send_frame).once.and_raise(IOError.new("mock io/error"))
        EpicImplementationFail.stub!(:connect).with(no_args()).once.and_return(nil)
        @connection.transmit(@send_frame)
        EpicImplementationFail.stub!(:transmit).with(@send_frame).once.and_return(nil)
        @connection.transmit(@send_frame)
      end

      it "should reconnect when an IOError is received during a receive" do
        EpicImplementationFail.stub!(:receive).with(no_args()).once.and_raise(IOError.new("mock io/error"))
        EpicImplementationFail.stub!(:connect).with(no_args()).once.and_return(nil)
        @connection.receive
        EpicImplementationFail.stub!(:receive).with(no_args()).once.and_return(nil)
        @connection.receive
      end

      it "should not try to reconnect more than once within the specified timeout" do
        EpicImplementationFail.stub!(:receive).with(no_args()).once.and_raise(IOError.new("mock io/error"))
        EpicImplementationFail.stub!(:connect).with(no_args()).once.and_return(nil)
        thread = Thread.new do
          # We sleep for a bit to ensure that the first receive is called
          # If the connection is behaving properly, the receive should fail quickly
          # and the connection should sleep for the specified reconnect delay
          # after which it will attempt to connect again.
          # Our sleep time is less than the reconnect delay so that by the time
          # the connection is "re-established", the non-failing receive is in place.
          sleep(0.05)
          EpicImplementationFail.stub!(:receive).with(no_args()).once.and_return(nil)
        end
        @connection.receive
        @connection.receive
        thread.join
      end
    end
    
    describe "maximum retries" do
      module EpicImplementationFail; end
      class ::Stomper::ReliableConnection; include EpicImplementationFail; end
      before(:each) do
        @connection = ReliableConnection.new("stomp:///", :max_retries => 2, :delay => 0.1)
      end
    end
  end
end
