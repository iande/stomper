shared_examples_for "All Client Connections" do

  describe "connection initializers" do
    describe "explicit parameters" do
      it "should accept explicit parameters for host" do
        lambda { @connection.class.new('localhost') }.should_not raise_error
      end

      it "should accept explicit parameters for host and port" do
        lambda { @connection.class.new('localhost', 61613) }.should_not raise_error
      end

      it "should accept explicit parameters for host, port, user and passcode" do
        lambda { @connection.class.new('localhost', 61613, 'test_user', 's3cr3tz') }.should_not raise_error
      end

      it "should establish a secure connection explicitly" do
        pending "need to implement the SSL portion and figure out a proper way to test" do
          lambda { @connection.class.new('localhost', 61613, 'test_user', 's3cr3tz', true) }.should_not raise_error
        end
      end
    end

    describe "from uri" do
      it "should accept the stomp:/// uri (no host specified)" do
        lambda { @connection.class.new("stomp:///") }.should_not raise_error
      end

      it "should accept a uri specifying just the host" do
        lambda { @connection.class.new("stomp://localhost/") }.should_not raise_error
      end

      it "should accept a uri specifying host and port" do
        lambda { @connection.class.new("stomp://localhost:61613/") }.should_not raise_error
      end

      it "should accept a uri specifying host, port and credentials" do
        lambda { @connection.class.new("stomp://test_user:s3cr3tz@localhost:61613/") }.should_not raise_error
      end

      it "should accept a uri specifying a secure connection" do
        pending "need to implement the SSL portion and figure out a proper way to test" do
          lambda { @connection.class.new("stomp+ssl://localhost") }.should_not raise_error
        end
      end

      it "should not accept a bogus URI" do
        lambda { @connection.class.new("stomp://localhost:garbage") }.should raise_error
      end

    end
  end

  describe "connection control" do
    it "should provide the appropriate all connection control and status methods" do
      @connection.should respond_to(:connect)
      @connection.should respond_to(:disconnect)
      @connection.should respond_to(:close)
      @connection.should respond_to(:connected?)
    end

    it "should not report it is connected after close is called" do
      @connection.connected?.should be_true
      @connection.close
      @connection.connected?.should be_false
    end
    
    it "should not report it is connected after disconnect is called" do
      @connection.connected?.should be_true
      @connection.disconnect
      @connection.connected?.should be_false
    end
  end

  describe "connection IO" do
    it "should provide methods for receiving frames and writing frames" do
      @connection.should respond_to(:transmit)
      @connection.should respond_to(:receive)
    end

    it "the first frame received should be CONNECTED" do
      @connection.connected?.should be_true
      @frame = @connection.receive while @frame.nil?
      @frame.should be_an_instance_of(Stomper::Frames::Connected)
    end

    it "should transmit frames" do
      # Clear out the CONNECTED frame.
      @frame = @connection.receive while @frame.nil?
      @frame = nil
      @connection.transmit(Stomper::Frames::Subscribe.new("/topic/test_topic"))
      @connection.transmit(Stomper::Frames::Send.new("/topic/test_topic", "hello"))
      @frame = @connection.receive while @frame.nil?
      @frame.should be_an_instance_of(Stomper::Frames::Message)
      @frame.body.should == "hello"
    end
  end
end
