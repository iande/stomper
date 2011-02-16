# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe SubscriptionManager do
    before(:each) do
      @connection = mock("connection")
    end
    
    it "should bind to the on_receipt event handler" do
      receipt = mock('receipt')
      @connection.should_receive(:on_message)
      @subscription_manager = SubscriptionManager.new(@connection)
    end
  end
end
