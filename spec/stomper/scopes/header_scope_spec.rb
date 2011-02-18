# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Scopes
  describe HeaderScope do
    before(:each) do
      @connection = mock("connection", :is_a? => true, :version => '1.1')
      @headers = { :global_1 => 'turbo', 'global_2' => 'is me', :persistent => true }
      @connection.stub!(:subscription_manager).and_return(mock('subscription manager', {
        :subscribed_id? => true
      }))
      @scope = HeaderScope.new(@connection, @headers)
    end
    
    it "should apply the headers to any frame generated on its Common interface" do
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SEND'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'BEGIN'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'UNSUBSCRIBE'))
      @scope.send("/queue/test", "body of message", { :local_1 => 'my header' })
      @scope.begin("transaction-1234", { :local_2 => 'other header'})
      @scope.unsubscribe('no-real-destination')
    end
    
    it "should evaluate a proc through itself if one is provided" do
      scope_block = lambda do |h|
        h.abort('transaction-1234')
        h.subscribe('/queue/test')
        h.commit('transaction-1234')
      end
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'ABORT'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'SUBSCRIBE'))
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(@headers, 'COMMIT'))
      @scope.apply_to(scope_block)
    end
    
    it "should override its headers with those passed through the frame methods" do
      overridden_headers = @headers.merge(:persistent => 'false')
      @connection.should_receive(:transmit).with(stomper_frame_with_headers(overridden_headers, 'SEND'))
      @scope.send('/queue/test', 'body of message', { :persistent => false })
    end
    
    describe "nested header scopes" do
      before(:each) do
        @child_headers = { :child_1 => 1985, 'persistent' => false }
        @child_scope = HeaderScope.new(@scope, @child_headers)
        @merged_headers = { :global_1 => 'turbo', :global_2 => 'is me', :persistent => false, :child_1 => 1985 }
      end
      it "should include headers from the parent scope" do
        @connection.should_receive(:transmit).with(stomper_frame_with_headers(@merged_headers, 'SEND'))
        @child_scope.send('/queue/test', 'body of message')
      end
    end
  end
end