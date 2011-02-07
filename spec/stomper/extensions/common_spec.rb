# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions
  describe Common do
    before(:each) do
      @common = mock("common")
      @common.extend Common
    end
    
    it "should transmit an ABORT frame" do
      @common.should_receive(:transmit).with(stomper_frame_with_headers({'transaction' => 'tx-1234'}, 'ABORT'))
      @common.abort('tx-1234')
    end
    
    it "should transmit a BEGIN frame" do
      @common.should_receive(:transmit).with(stomper_frame_with_headers({'transaction' => 'tx-3124'}, 'BEGIN'))
      @common.begin('tx-3124')
    end
    
    it "should transmit a COMMIT frame" do
      @common.should_receive(:transmit).with(stomper_frame_with_headers({'transaction' => 'tx-4321'}, 'COMMIT'))
      @common.commit('tx-4321')
    end
    
    it "should transmit a SEND frame with :snd" do
      @common.should_receive(:transmit).with(stomper_frame('testing :snd', {'destination' => '/queue/test_snd'}, 'SEND'))
      @common.snd('/queue/test_snd', 'testing :snd')
    end
    
    it "should transmit a SEND frame with :put" do
      @common.should_receive(:transmit).with(stomper_frame('testing :put', {'destination' => '/queue/test_put'}, 'SEND'))
      @common.put('/queue/test_put', 'testing :put')
    end
    
    it "should transmit a SUBSCRIBE frame" do
      @common.should_receive(:transmit).with(stomper_frame_with_headers({'destination' => '/queue/test_subscribe'}, 'SUBSCRIBE'))
      @common.subscribe('/queue/test_subscribe')
    end
    
    it "should transmit an UNSUBSCRIBE frame for a given subscription ID" do
      @common.should_receive(:transmit).with(stomper_frame_with_headers({'id' => 'subscription-1234'}, 'UNSUBSCRIBE'))
      @common.unsubscribe('subscription-1234')
    end
    
    it "should transmit an UNSUBSCRIBE frame for a given SUBSCRIBE frame" do
      subscribe = ::Stomper::Frame.new('SUBSCRIBE', { :id => 'id-in-frame-4321' })
      @common.should_receive(:transmit).with(stomper_frame_with_headers({'id' => 'id-in-frame-4321'}, 'UNSUBSCRIBE'))
      @common.unsubscribe(subscribe)
    end
  end
end
