require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

module Stomper
  module Frames
    describe ServerFrame do
      before(:each) do
        @server_frame = ServerFrame.new("SERVER COMMAND")
      end

      it "should provide a method for subclasses to register the command they handle" do
        ServerFrame.should respond_to(:factory_for)
      end

      it "should build an appropriate object for a given server frame" do
        @built_frame = ServerFrame.build("MESSAGE", {:'message-id' => 'msg-001', :transaction => 'tx-test', :subscription => 'sub-test'}, "message body")
        @built_frame.should be_an_instance_of(Message)
        @built_frame.headers[:transaction].should == "tx-test"
        @built_frame.headers[:subscription].should == "sub-test"
        @built_frame.headers[:'message-id'].should == "msg-001"
        @built_frame.body.should == "message body"
        @built_frame = ServerFrame.build("AN UNKNOWN COMMAND", {:a_header => "test"}, "a body")
        @built_frame.should be_an_instance_of(ServerFrame)
        @built_frame.command.should == "AN UNKNOWN COMMAND"
        @built_frame.headers[:a_header].should == "test"
        @built_frame.body.should == "a body"
        class MockServerFrame < ServerFrame
          factory_for :testing
          def initialize(headers, body)
            super('TESTING', headers, body)
          end
        end
        @built_frame = ServerFrame.build("TESTING", {:a_header => "test"}, "a body")
        @built_frame.should be_an_instance_of(MockServerFrame)
        @built_frame.headers[:a_header].should == "test"
        @built_frame.body.should == "a body"
      end

      describe "server frames" do
        describe Connected do
          it "should be registered" do
            @server_frame = ServerFrame.build("CONNECTED", {:a_header => 'test'}, "test body")
            @server_frame.should be_an_instance_of(Connected)
            @server_frame.headers[:a_header].should == "test"
            @server_frame.body.should == "test body"
          end
        end
        describe Error do
          it "should be registered" do
            @server_frame = ServerFrame.build("ERROR", {:a_header => 'test'}, "test body")
            @server_frame.should be_an_instance_of(Error)
            @server_frame.headers[:a_header].should == "test"
            @server_frame.body.should == "test body"
          end
        end
        describe Message do
          it "should be registered" do
            @server_frame = ServerFrame.build("MESSAGE", {:a_header => 'test'}, "test body")
            @server_frame.should be_an_instance_of(Message)
            @server_frame.headers[:a_header].should == "test"
            @server_frame.body.should == "test body"
          end

          it "should provide the convenience attributes" do
            @message = Message.new({:destination => '/queue/testing', :subscription => 'sub-001', :'message-id' => 'msg-001'}, "test body")
            @message.id.should == "msg-001"
            @message.destination.should == "/queue/testing"
            @message.subscription.should == "sub-001"
          end
        end
        describe Receipt do
          it "should be registered" do
            @server_frame = ServerFrame.build("RECEIPT", {:a_header => 'test'}, "test body")
            @server_frame.should be_an_instance_of(Receipt)
            @server_frame.headers[:a_header].should == "test"
            @server_frame.body.should == "test body"
          end

          it "should provide the convenience attributes" do
            @receipt = Receipt.new({:'receipt-id' => 'who the receipt is for'}, "test body")
            @receipt.for.should == "who the receipt is for"
          end
        end
      end
    end
  end
end
