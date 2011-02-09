# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe Connection do
    before(:each) do
      @uri = mock("uri", :path => '',
        :query => '',
        :is_a? => true,
        :host => nil,
        :user => nil,
        :password => nil)
    end
    
    describe "default configuration" do
      before(:each) do
        @uri.stub!(:host => 'uri.host.name')
        @connection = Connection.new(@uri)
      end
      
      it "should have an empty default destination" do
        @connection.default_destination.should == ''
      end
      
      it "should default to all supported protocol versions" do
        @connection.versions.should == Stomper::Connection::PROTOCOL_VERSIONS
      end
      
      it "should default to no heartbeating" do
        @connection.heartbeats.should == [ 0, 0 ]
      end
      
      it "should default the virtual host to the URI's host" do
        @connection.host.should == 'uri.host.name'
      end
      
      it "should have an empty login and passcode" do
        @connection.login.should == ''
        @connection.passcode.should == ''
      end
      
      it "should include Extensions::Common" do
        @connection.should be_a_kind_of(::Stomper::Extensions::Common)
      end
      
      it "should include Extensions::Events" do
        @connection.should be_a_kind_of(::Stomper::Extensions::Events)
      end
      
      it "should include Extensions::Scoping" do
        @connection.should be_a_kind_of(::Stomper::Extensions::Scoping)
      end
    end
    
    describe "configuration through uri" do
      before(:each) do
        @uri.stub!(:path => '/path/dest',
          :query => 'versions=1.1&versions=1.0&default_destination=/query/dest')
      end
      
      it "should use the path of the URI as a default destination" do
        @uri.stub!(:query => '')
        connection = Connection.new(@uri)
        connection.default_destination.should == '/path/dest'
      end
      
      it "should use the default_destination query parameter as a default destination" do
        @uri.stub!(:path => '')
        connection = Connection.new(@uri)
        connection.default_destination.should == '/query/dest'
      end
      
      it "should favor the default_destination query over the path" do
        connection = Connection.new(@uri)
        connection.default_destination.should == '/query/dest'
      end
      
      it "should use the version query parameter" do
        connection = Connection.new(@uri)
        connection.versions.should == ['1.0', '1.1']
        
        @uri.stub!(:query => 'versions=1.1&versions=1.1')
        connection = Connection.new(@uri)
        connection.versions.should == ['1.1']
        
        @uri.stub!(:query => 'versions=1.0')
        connection = Connection.new(@uri)
        connection.versions.should == ['1.0']
      end
      
      it "should use the user and password of the URI" do
        @uri.stub!(:user => 'some guy')
        @uri.stub!(:password => 's3cr3tk3yz')
        connection = Connection.new(@uri)
        connection.login.should == 'some guy'
        connection.passcode.should == 's3cr3tk3yz'
      end
      
      it "should use the login and passcode query parameters" do
        @uri.stub!(:query => 'login=other%20dude&passcode=yermom')
        connection = Connection.new(@uri)
        connection.login.should == 'other dude'
        connection.passcode.should == 'yermom'
      end
    end
    
    describe "configuration through options" do
      it "should use the :default_destination option as a default destination" do
        connection = Connection.new(@uri, { 'default_destination' => '/options/dest' })
        connection.default_destination.should == '/options/dest'

        connection = Connection.new(@uri, { :default_destination => '/options/dest' })
        connection.default_destination.should == '/options/dest'
      end
      
      it "should use the version option" do
        connection = Connection.new(@uri, { :versions => '1.0' })
        connection.versions.should == [ '1.0' ]

        connection = Connection.new(@uri, { 'versions' => ['1.1', '1.1'] })
        connection.versions.should == ['1.1']
      end
      
      it "should use the login and passcode options" do
        connection = Connection.new(@uri, { :login => 'me also', 'passcode' => 'm3t00'})
        connection.login.should == 'me also'
        connection.passcode.should == 'm3t00'
      end
    end
    
    describe "configuration collision" do
      it "should favor the :default_destination option over the default_destination query over the URI path" do
        @uri.stub!(:query => 'default_destination=/query/dest')
        @uri.stub!(:path => '/path/dest')
        connection = Connection.new(@uri)
        connection.default_destination.should == '/query/dest'
        connection = Connection.new(@uri, { :default_destination => '/options/dest' })
        connection.default_destination.should == '/options/dest'
      end
      
      it "should favor the login/passcode option over the query over the user/password of the URI" do
        @uri.stub!(:user => 'ian', :password => 's3cr3tz')
        @uri.stub!(:query => 'login=not%20ian&passcode=my_super_secret_key')
        connection = Connection.new(@uri)
        connection.login.should == 'not ian'
        connection.passcode.should == 'my_super_secret_key'
        connection = Connection.new(@uri, { :login => '', :passcode => nil })
        connection.login.should == ''
        connection.passcode.should == ''
      end
      
      it "should favor the version option over the query parameter" do
        @uri.stub!(:query => 'versions=1.1&versions=1.1')
        connection = Connection.new(@uri, { :versions => '1.0' })
        connection.versions.should == [ '1.0' ]
      end
    end
    
    describe "version configuration" do
      before(:each) do
        @connection = Connection.new(@uri)
      end
      
      it "should only use versions numbers that are supported" do
        @connection.versions = [ '1.1', '9.3', '1.0', '7.garbage' ]
        @connection.versions.should == ['1.0', '1.1']
      end
      
      it "should raise an error when no supported versions have been specified" do
        lambda { @connection.versions = [ '2.0', '3.8', '1.2' ] }.should raise_error(::Stomper::Errors::UnsupportedProtocolVersionError)
      end
    end
    
    describe "Connection IO" do
      before(:each) do
        @socket = mock('socket', :closed? => false, :close => true, :shutdown => true)
        @serializer = mock('serializer', :extend_for_protocol => true)
        @connected_frame = mock('CONNECTED', :command => 'CONNECTED')
        @serializer.should_receive(:read_frame).and_return(@connected_frame)
        @uri.should_receive(:create_socket).and_return(@socket)
        ::Stomper::Extensions::FrameSerializer.stub!(:new => @serializer)
        @connection = Connection.new(@uri)
      end
      
      it "should test connecting with a string instead of a URI"
      it "should test actually connecting, or something much closer to it"
      
      describe "connection state events" do
        before(:each) do
          @connected_frame.should_receive(:[]).with(:version).and_return('1.1')
          @serializer.should_receive(:write_frame).with(stomper_frame_with_headers({}, 'CONNECT')).once.and_return { |f| f }
        end
        
        it "should trigger on_connection_established after connecting" do
          triggered = false
          @connection.on_connection_established { triggered = true }
          @connection.connect
          triggered.should be_true
        end
        
        it "should trigger on_connection_closed & on_connection_disconnected after disconnecting" do
          triggered = [false, false]
          @connection.on_connection_closed { triggered[0] = true }
          @connection.on_connection_disconnected { triggered[1] = true }
          @connection.connect
          @connection.disconnect
          triggered.should == [true, true]
        end
        
        it "should trigger on_connection_died before transmitting if the connection is dead" do
          triggered = false
          @connection.on_connection_died { triggered = true }
          @connection.connect
          @serializer.stub!(:write_frame).and_return { |f| f }
          @connection.stub!(:alive?).and_return(false)
          @connection.transmit(::Stomper::Frame.new('ACK'))
          triggered.should be_true
        end
        
        it "should trigger on_connection_died before receiving if the connection is dead" do
          triggered = false
          @connection.on_connection_died { triggered = true }
          @connection.connect
          @connection.stub!(:alive?).and_return(false)
          @serializer.stub!(:read_frame).and_return(::Stomper::Frame.new('MESSAGE'))
          @connection.receive
          triggered.should be_true
        end
        
        it "should trigger on_connection_died before receiving non-blocking (even if not ready) if the connection is dead" do
          triggered = false
          @connection.on_connection_died { triggered = true }
          @connection.connect
          @connection.stub!(:alive?).and_return(false)
          @serializer.stub!(:read_frame).and_return(::Stomper::Frame.new('MESSAGE'))
          @socket.stub!(:ready?).and_return(false)
          @connection.receive_nonblock
          triggered.should be_true
        end
        
        it "should trigger on_connection_terminated if the socket raises an IOError while transmitting" do
          triggered = false
          @connection.on_connection_terminated { triggered = true }
          @connection.connect
          @serializer.stub!(:write_frame).and_raise(IOError.new('io error'))
          lambda { @connection.transmit(::Stomper::Frame.new('ACK')) }.should raise_error(IOError)
          triggered.should be_true
        end
        
        it "should trigger on_connection_terminated if the socket raises a SystemCallError while transmitting" do
          triggered = false
          @connection.on_connection_terminated { triggered = true }
          @connection.connect
          @serializer.stub!(:write_frame).and_raise(SystemCallError.new('syscall error'))
          lambda { @connection.transmit(::Stomper::Frame.new('ACK')) }.should raise_error(SystemCallError)
          triggered.should be_true
        end
        
        it "should trigger on_connection_terminated if the socket raises an IOError while receiving" do
          triggered = false
          @connection.on_connection_terminated { triggered = true }
          @connection.connect
          @serializer.stub!(:read_frame).and_raise(IOError.new('io error'))
          lambda { @connection.receive }.should raise_error(IOError)
          triggered.should be_true
        end
        
        it "should trigger on_connection_terminated if the socket raises a SystemCallError while receiving" do
          triggered = false
          @connection.on_connection_terminated { triggered = true }
          @connection.connect
          @serializer.stub!(:read_frame).and_raise(SystemCallError.new('syscall error'))
          lambda { @connection.receive }.should raise_error(SystemCallError)
          triggered.should be_true
        end
        
      end
      
      describe "frame events" do
        before(:each) do
          @connected_frame.should_receive(:[]).with(:version).and_return('1.1')
          @serializer.should_receive(:write_frame).with(stomper_frame_with_headers({}, 'CONNECT')).once.and_return { |f| f }
          @connection.connect
          @serializer.stub!(:write_frame).and_return { |f| f }
        end
        
        it "should trigger all on_abort handlers when an ABORT frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_abort { triggered[0] = true }
          @connection.on_abort { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('ABORT'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_ack handlers when an ACK frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_ack { triggered[0] = true }
          @connection.on_ack { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('ACK'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_begin handlers when a BEGIN frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_begin { triggered[0] = true }
          @connection.on_begin { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('BEGIN'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_commit handlers when a COMMIT frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_commit { triggered[0] = true }
          @connection.on_commit { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('COMMIT'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_connect & on_stomp handlers when a CONNECT frame is transmitted" do
          triggered = [ false, false, false, false, false ]
          @connection.on_connect { triggered[0] = true }
          @connection.on_stomp { triggered[1] = true }
          @connection.on_connect { triggered[2] = true }
          @connection.before_transmitting { triggered[3] = true }
          @connection.after_transmitting { triggered[4] = true }
          @connection.transmit(::Stomper::Frame.new('CONNECT'))
          triggered.should == [true, true, true, true, true]
        end
        
        it "should trigger all on_disconnect handlers when a DISCONNECT frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_disconnect { triggered[0] = true }
          @connection.on_disconnect { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('DISCONNECT'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_nack handlers when a NACK frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_nack { triggered[0] = true }
          @connection.on_nack { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('NACK'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_send handlers when a SEND frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_send { triggered[0] = true }
          @connection.on_send { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('SEND'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_subscribe handlers when a SUBSCRIBE frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_subscribe { triggered[0] = true }
          @connection.on_subscribe { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('SUBSCRIBE'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_unsubscribe handlers when an UNSUBSCRIBE frame is transmitted" do
          triggered = [ false, false, false, false ]
          @connection.on_unsubscribe { triggered[0] = true }
          @connection.on_unsubscribe { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new('UNSUBSCRIBE'))
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_client_beat handlers when a frame is transmitted without a command" do
          triggered = [ false, false, false, false ]
          @connection.on_client_beat { triggered[0] = true }
          @connection.on_client_beat { triggered[1] = true }
          @connection.before_transmitting { triggered[2] = true }
          @connection.after_transmitting { triggered[3] = true }
          @connection.transmit(::Stomper::Frame.new)
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_connected handlers when a CONNECTED frame is received" do
          triggered = [ false, false, false, false ]
          @connection.on_connected { triggered[0] = true }
          @connection.on_connected { triggered[1] = true }
          @connection.before_receiving { triggered[2] = true }
          @connection.after_receiving { triggered[3] = true }
          @serializer.should_receive(:read_frame).and_return(::Stomper::Frame.new('CONNECTED'))
          @connection.receive
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_message handlers when a MESSAGE frame is received" do
          triggered = [ false, false, false, false ]
          @connection.on_message { triggered[0] = true }
          @connection.on_message { triggered[1] = true }
          @connection.before_receiving { triggered[2] = true }
          @connection.after_receiving { triggered[3] = true }
          @serializer.should_receive(:read_frame).and_return(::Stomper::Frame.new('MESSAGE'))
          @connection.receive
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_error handlers when an ERROR frame is received" do
          triggered = [ false, false, false, false ]
          @connection.on_error { triggered[0] = true }
          @connection.on_error { triggered[1] = true }
          @connection.before_receiving { triggered[2] = true }
          @connection.after_receiving { triggered[3] = true }
          @serializer.should_receive(:read_frame).and_return(::Stomper::Frame.new('ERROR'))
          @connection.receive
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_receipt handlers when a RECEIPT frame is received" do
          triggered = [ false, false, false, false ]
          @connection.on_receipt { triggered[0] = true }
          @connection.on_receipt { triggered[1] = true }
          @connection.before_receiving { triggered[2] = true }
          @connection.after_receiving { triggered[3] = true }
          @serializer.should_receive(:read_frame).and_return(::Stomper::Frame.new('RECEIPT'))
          @connection.receive
          triggered.should == [true, true, true, true]
        end
        
        it "should trigger all on_broker_beat handlers when a frame is received without a command" do
          triggered = [ false, false, false, false ]
          @connection.on_broker_beat { triggered[0] = true }
          @connection.on_broker_beat { triggered[1] = true }
          @connection.before_receiving { triggered[2] = true }
          @connection.after_receiving { triggered[3] = true }
          @serializer.should_receive(:read_frame).and_return(::Stomper::Frame.new)
          @connection.receive
          triggered.should == [true, true, true, true]
        end
      end
      
      describe "version negotiation" do
        it "should include Extensions::Protocols::V1_0 if the negotiated protocol is 1.0" do
          @serializer.should_receive(:write_frame).with(stomper_frame_with_headers({:'accept-version' => '1.0,1.1', :'heart-beat' => '0,0'}, 'CONNECT'))
          @connected_frame.should_receive(:[]).with(:version).and_return('1.0')
          @connection.connect
          @connection.version.should == '1.0'
          @connection.should be_a_kind_of(::Stomper::Extensions::Protocols::V1_0)
        end

        it "should include Extensions::Protocols::V1_0 if the negotiated protocol is 1.1" do
          @serializer.should_receive(:write_frame).with(stomper_frame_with_headers({:'accept-version' => '1.0,1.1', :'heart-beat' => '0,0'}, 'CONNECT'))
          @connected_frame.should_receive(:[]).with(:version).and_return('1.1')
          @connection.connect
          @connection.version.should == '1.1'
          @connection.should be_a_kind_of(::Stomper::Extensions::Protocols::V1_1)
        end
        
        it "should raise an error if the version returned by the broker is not in the list of acceptable versions" do
          @serializer.should_receive(:write_frame).with(stomper_frame_with_headers({:'accept-version' => '1.0,1.1', :'heart-beat' => '0,0'}, 'CONNECT'))
          @connected_frame.should_receive(:[]).with(:version).and_return('2.0')
          lambda { @connection.connect }.should raise_error(::Stomper::Errors::UnsupportedProtocolVersionError)
        end
      end
    end
  end
end
