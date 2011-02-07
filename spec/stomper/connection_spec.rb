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
  end
end
