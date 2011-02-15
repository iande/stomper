# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe Sockets do
    describe Sockets::TCP do
      before(:each) do
        @tcp_socket = mock('tcp socket')
        ::TCPSocket.stub(:new => @tcp_socket)
        @tcp = ::Stomper::Sockets::TCP.new('host', 12345)
      end
      it "should create a new instance that delegates to TCPSocket" do
        @tcp_socket.should_receive(:ready?).and_return(true)
        @tcp_socket.should_receive(:read).and_return('this is what we read')
        @tcp_socket.should_receive(:write).with('blather').and_return(42)
        
        @tcp.ready?.should be_true
        @tcp.read.should == 'this is what we read'
        @tcp.write('blather').should == 42
      end
    end
    
    describe Sockets::SSL do
      before(:each) do
        @tcp_socket = mock('tcp socket')
        ::TCPSocket.stub(:new => @tcp_socket)
        @ssl_socket = mock('ssl socket', :sync_close= => true, :connect => true, :io => @tcp_socket)
        ::OpenSSL::SSL::SSLSocket.stub(:new => @ssl_socket)
      end
      
      it "should use the underlying TCP socket for :ready?" do
        @ssl_socket.should_receive(:post_connection_check).with('host').and_return(true)
        @ssl = ::Stomper::Sockets::SSL.new('host', 56789)
        @tcp_socket.should_receive(:ready?).and_return(true)
        
        @ssl.ready?.should be_true
      end
      
      it "should use the underlying TCP socket for :shutdown" do
        @ssl_socket.should_receive(:post_connection_check).with('host').and_return(true)
        @ssl = ::Stomper::Sockets::SSL.new('host', 56789)
        @tcp_socket.should_receive(:shutdown).with('args').and_return(true)
        
        @ssl.shutdown('args').should be_true
      end
      
      it "should delegate unknown methods to SSLSocket" do
        @ssl_socket.should_receive(:post_connection_check).with('host').and_return(true)
        @ssl = ::Stomper::Sockets::SSL.new('host', 56789)
        @ssl_socket.should_receive(:read).and_return('this is what we read')
        @ssl_socket.should_receive(:write).with('blather').and_return(42)
        
        @ssl.read.should == 'this is what we read'
        @ssl.write('blather').should == 42
      end
      
      it "should not perform a post_connection_check if option value is nil or false" do
        @ssl_socket.should_not_receive(:post_connection_check)
        @ssl = ::Stomper::Sockets::SSL.new('host', 56789, { :post_connection_check => false })
        @ssl = ::Stomper::Sockets::SSL.new('host', 56789, { :post_connection_check => nil })
      end
      
      it "should perform a post_connection_check against the host if the option value is true" do
        @ssl_socket.should_receive(:post_connection_check).with('host.name.tld').and_return(true)
        @ssl = ::Stomper::Sockets::SSL.new('host.name.tld', 56789, { :post_connection_check => true })
      end
      
      it "should perform a post_connection_check against the option value otherwise" do
        @ssl_socket.should_receive(:post_connection_check).with('user specified name').and_return(true)
        @ssl = ::Stomper::Sockets::SSL.new('host.name.tld', 56789, { :post_connection_check => 'user specified name' })
        
        @ssl_socket.should_receive(:post_connection_check).with(66).and_return(true)
        @ssl = ::Stomper::Sockets::SSL.new('host.name.tld', 56789, { :post_connection_check => 66 })
      end
      
      describe "SSL Context Options" do
        before(:each) do
          @ssl_context = mock('context')
          ::OpenSSL::SSL::SSLContext.stub(:new => @ssl_context)
        end
        
        it "should apply sensible defaults when no options are specified" do
          @ssl_context.should_receive(:verify_mode=).with(::OpenSSL::SSL::VERIFY_PEER |
            ::OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT)
          @ssl_context.should_receive(:ca_file=).with(nil)
          @ssl_context.should_receive(:ca_path=).with(nil)
          @ssl_context.should_receive(:cert=).with(nil)
          @ssl_context.should_receive(:key=).with(nil)
          
          @ssl_socket.should_receive(:post_connection_check).with('host').and_return(true)
          @ssl = ::Stomper::Sockets::SSL.new('host', 56789)
        end
        
        it "should override sensible defaults with supplied options" do
          @ssl_context.should_receive(:verify_mode=).with("kage")
          @ssl_context.should_receive(:ca_file=).with("jables")
          @ssl_context.should_receive(:ca_path=).with("the d")
          @ssl_context.should_receive(:cert=).with("scepter")
          @ssl_context.should_receive(:key=).with("key")
          
          @ssl_socket.should_receive(:post_connection_check).with('host').and_return(true)
          @ssl = ::Stomper::Sockets::SSL.new('host', 56789, {
            :verify_mode => "kage",
            :ca_file => "jables",
            :ca_path => "the d",
            :cert => "scepter",
            :key => "key"
          })
        end
      end
    end
  end
end
