require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

module Stomper::Frames
  describe ClientFrame do
    before(:each) do
      ClientFrame.generate_content_length = true
      @client_frame = ClientFrame.new('COMMAND')
    end

    it "should be provide a headers as an instance of Headers" do
      @client_frame.headers.should be_an_instance_of(Stomper::Frames::Headers)
    end

    it "should be convertable into a stomp frame" do
      @client_frame.to_stomp.should == "COMMAND\n\n\0"
      @client_frame.headers.destination = "/queue/test/1"
      @client_frame.headers['transaction-id'] = '2'
      @client_frame.headers[:ack] = 'client'
      @client_frame.to_stomp.should == "COMMAND\nack:client\ndestination:/queue/test/1\ntransaction-id:2\n\n\0"
    end

    describe "generating content-length header" do
      it "should provide the header by default, overriding any existing header" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {'content-length' => 1}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:#{@frame_body.bytesize}\n\n#{@frame_body}\0"
      end

      it "should not provide the header if the class option is set to false, unless explicitly set on the frame in particular" do
        ClientFrame.generate_content_length = false
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\n\n#{@frame_body}\0"
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.generate_content_length = true
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:#{@frame_body.bytesize}\n\n#{@frame_body}\0"
      end

      it "should not provide the header if instance option is set false, when the class option is true" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.generate_content_length = false
        @client_frame.to_stomp.should == "COMMAND\n\n#{@frame_body}\0"
        @client_frame = ClientFrame.new('COMMAND', {:generate_content_length => false}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\n\n#{@frame_body}\0"
      end

      it "should not overwrite an explicit content-length header when option is off at class or instance level" do
        @frame_body = 'testing'
        @client_frame = ClientFrame.new('COMMAND', { 'content-length' => 4}, @frame_body)
        @client_frame.generate_content_length = false
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:4\n\n#{@frame_body}\0"
        ClientFrame.generate_content_length = false
        @client_frame = ClientFrame.new('COMMAND', {'content-length' => 2}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:2\n\n#{@frame_body}\0"
      end

      it "should the class option should be scoped to the class it is set on" do
        @frame_body = 'testing'
        Send.generate_content_length = false
        @send_frame = Send.new('/queue/test/1', @frame_body)
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\ncontent-length:#{@frame_body.bytesize}\n\n#{@frame_body}\0"
        @send_frame.to_stomp.should == "SEND\ndestination:#{@send_frame.headers.destination}\n\n#{@frame_body}\0"
        Send.generate_content_length = true
        ClientFrame.generate_content_length = false
        @send_frame = Send.new('/queue/test/1', @frame_body)
        @client_frame = ClientFrame.new('COMMAND', {}, @frame_body)
        @client_frame.to_stomp.should == "COMMAND\n\n#{@frame_body}\0"
        @send_frame.to_stomp.should == "SEND\ncontent-length:#{@frame_body.bytesize}\ndestination:#{@send_frame.headers.destination}\n\n#{@frame_body}\0"
      end
    end
    describe "client frames" do
      describe Abort do
        it "should produce a proper stomp message" do
          @abort = Abort.new("transaction-test", { :a_header => 'test'})
          @abort.to_stomp.should == "ABORT\na_header:test\ntransaction:transaction-test\n\n\0"
        end
      end
      describe Ack do
        it "should produce a proper stomp message" do
          @ack = Ack.new("message-test", { :a_header => 'test'})
          @ack.to_stomp.should == "ACK\na_header:test\nmessage-id:message-test\n\n\0"
        end

        it "should provide an Ack for a given message frame" do
          @ack = Ack.ack_for(Message.new({'message-id' => 'test'}, "a body"))
          @ack.to_stomp.should == "ACK\nmessage-id:test\n\n\0"
          @ack = Ack.ack_for(Message.new({'message-id' => 'test', 'transaction' => 'tx-test'}, "a body"))
          @ack.to_stomp.should == "ACK\nmessage-id:test\ntransaction:tx-test\n\n\0"
        end

      end
      describe Begin do
        it "should produce a proper stomp message" do
          @begin = Begin.new("transaction-test", { :a_header => 'test'})
          @begin.to_stomp.should == "BEGIN\na_header:test\ntransaction:transaction-test\n\n\0"
        end
      end
      describe Commit do
        it "should produce a proper stomp message" do
          @commit = Commit.new("transaction-test", { :a_header => 'test'})
          @commit.to_stomp.should == "COMMIT\na_header:test\ntransaction:transaction-test\n\n\0"
        end
      end
      describe Connect do
        it "should produce a proper stomp message" do
          @connect = Connect.new('uzer','s3cr3t', { :a_header => 'test' })
          @connect.to_stomp.should == "CONNECT\na_header:test\nlogin:uzer\npasscode:s3cr3t\n\n\0"
        end
      end
      describe Disconnect do
        it "should produce a proper stomp message" do
          @disconnect = Disconnect.new({ :a_header => 'test'})
          @disconnect.to_stomp.should == "DISCONNECT\na_header:test\n\n\0"
        end
      end
      describe Send do
        it "should produce a proper stomp message" do
          @send = Send.new("/queue/a/target", "a body", { :a_header => 'test'})
          @send.to_stomp.should == "SEND\na_header:test\ncontent-length:6\ndestination:/queue/a/target\n\na body\0"
        end
      end
      describe Subscribe do
        it "should produce a proper stomp message" do
          @subscribe = Subscribe.new("/topic/some/target", { :a_header => 'test'})
          @subscribe.to_stomp.should == "SUBSCRIBE\na_header:test\nack:auto\ndestination:/topic/some/target\n\n\0"
        end
      end
      describe Unsubscribe do
        it "should produce a proper stomp message" do
          @unsubscribe = Unsubscribe.new("/topic/target.name.path", { :a_header => 'test'})
          @unsubscribe.to_stomp.should == "UNSUBSCRIBE\na_header:test\ndestination:/topic/target.name.path\n\n\0"
        end
      end
    end
  end
end
