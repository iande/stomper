require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'open-uri'

module Stomper
  describe "Open URI Interface" do
    describe "basic interface" do
      it "should be able to connect through open-uri style" do
        lambda { open("stomp:///") { |s| } }.should_not raise_error
      end
      it "should provide a 'put' method" do
        open("stomp:///") { |s| s.should respond_to(:put) }
      end
      it "should provide a 'puts' method" do
        open("stomp:///") { |s| s.should respond_to(:puts) }
      end
      it "should provide a 'write' method" do
        open("stomp:///") { |s| s.should respond_to(:write) }
      end
      it "should provide a 'get' method" do
        open("stomp:///") { |s| s.should respond_to(:get) }
      end
      it "should provide a 'gets' method" do
        open("stomp:///") { |s| s.should respond_to(:gets) }
      end
      it "should provide a 'read' method" do
        open("stomp:///") { |s| s.should respond_to(:read) }
      end
    end

    describe "automatic closing" do
      it "should automatically connect then disconnect when the block completes" do
        connection = open("stomp:///") { |s| s.connected?.should be_true; s }
        connection.connected?.should be_false
      end

      it "should automatically disconnect if the block raises an exception" do
        connection = nil
        begin
          open("stomp:///") { |s| connection = s; raise ArgumentError, "some error" }
        rescue ArgumentError
        end
        connection.connected?.should be_false
      end
    end

    describe "message sending" do
      it "should transmit a SEND frame for puts on the URI's specified destination with no content-length" do
        open("stomp://localhost/queue/testing") do |s|
          frame = s.puts("a test message")
          frame.should be_a_kind_of(Stomper::Frames::Send)
          frame.headers[:destination].should == "/queue/testing"
          frame.headers[:'content-length'].should be_nil
          frame.body.should == "a test message"
        end
      end
      it "should transmit a SEND frame for put on the URI's specified destination with no content-length" do
        open("stomp://localhost/queue/testing") do |s|
          frame = s.put("a test message")
          frame.should be_a_kind_of(Stomper::Frames::Send)
          frame.headers[:destination].should == "/queue/testing"
          frame.headers[:'content-length'].should be_nil
          frame.body.should == "a test message"
        end
      end
      it "should transmit a SEND frame for write on the URI's specified destination with a content-length" do
        open("stomp://localhost/queue/testing") do |s|
          frame = s.write("a test message")
          frame.should be_a_kind_of(Stomper::Frames::Send)
          frame.headers[:destination].should == "/queue/testing"
          frame.headers[:'content-length'].should == "a test message".length
          frame.body.should == "a test message"
        end
      end
    end

    describe "message receiving" do
      it "should receive the next message on the queue with gets" do
        open("stomp://localhost/queue/test_gets") do |s|
          s.puts "a test message"
          msg = s.gets
          msg.should be_a_kind_of(Stomper::Frames::Message)
          msg.body.should == "a test message"
          msg.destination.should == "/queue/test_gets"
        end
      end
      it "should receive the next message on the queue with get" do
        open("stomp://localhost/queue/test_get") do |s|
          s.puts "a test message"
          msg = s.get
          msg.should be_a_kind_of(Stomper::Frames::Message)
          msg.body.should == "a test message"
          msg.destination.should == "/queue/test_get"
        end
      end
      it "should receive the next message on the queue with read" do
        open("stomp://localhost/queue/test_read") do |s|
          s.puts "a test message"
          msg = s.read
          msg.should be_a_kind_of(Stomper::Frames::Message)
          msg.body.should == "a test message"
          msg.destination.should == "/queue/test_read"
        end
      end
      it "should receive 4 messages with an optional argument supplied to first" do
        open("stomp://localhost/queue/test_first_4") do |s|
          s.puts "test message 1"
          s.puts "test message 2"
          s.puts "test message 3"
          s.puts "test message 4"
          msgs = s.first(4)
          msgs.size.should == 4
          msgs.all? { |m| m.is_a?(Stomper::Frames::Message) }.should be_true
          msgs.map { |m| m.body }.should == ["test message 1", "test message 2", "test message 3", "test message 4"]
        end
      end
      it "should provide the each iterator" do
        open("stomp://localhost/queue/test_each") do |s|
          s.puts "fringe"
          s.write "dexter"
          s.put "nip/tuck"
          s.puts "futurama"
          s.write "frasier"
          s.each do |m|
            m.destination.should == "/queue/test_each"
            %w(fringe dexter nip/tuck futurama frasier).should include(m.body)
            break if m.body== "frasier"
          end
        end
      end
    end
  end
end