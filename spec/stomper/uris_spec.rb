# -*- encoding: utf-8 -*-
require 'spec_helper'

module URI
  describe STOMP do
    before(:each) do
      @uri = ::URI.parse('stomp:///')
      @uri_host = ::URI.parse('stomp://host.domain.tld:12345')
    end
    
    it "should be the class of URIs with a scheme of 'stomp' parsed by URI.parse" do
      @uri.should be_an_instance_of(::URI::STOMP)
    end
    
    it "should use port 61613 as a default if no port is specified" do
      @uri.port.should == 61613
    end
    
    it "should respond to :create_socket and return a TCP/IP socket built from its socket_factory" do
      socket = mock('socket')
      host_socket = mock('socket with host')
      ::Stomper::Sockets::TCP.should_receive(:new).with('localhost', 61613).and_return(socket)
      ::Stomper::Sockets::TCP.should_receive(:new).with('host.domain.tld', 12345).and_return(host_socket)
      
      @uri.create_socket.should equal(socket)
      @uri_host.create_socket.should equal(host_socket)
    end
  end
  
  describe STOMP_SSL do
    before(:each) do
      @uri = ::URI.parse("stomp+ssl:///")
      @uri_host = ::URI.parse('stomp+ssl://other.domain.tld:98765')
    end
    
    it "should be the class of URIs with a scheme of 'stomp+ssl' parsed by URI.parse" do
      @uri.should be_an_instance_of(::URI::STOMP_SSL)
    end
    
    it "should use port 61612 as a default if no port is specified" do
      @uri.port.should == 61612
    end
    
    it "should respond to :create_socket and return a TCP/IP socket built from its socket_factory" do
      socket = mock('socket')
      host_socket = mock('socket with host')
      ::Stomper::Sockets::SSL.should_receive(:new).with('localhost', 61612, {}).and_return(socket)
      ::Stomper::Sockets::SSL.should_receive(:new).with('other.domain.tld', 98765, {}).and_return(host_socket)
      
      @uri.create_socket.should equal(socket)
      @uri_host.create_socket.should equal(host_socket)
    end
  end
end
