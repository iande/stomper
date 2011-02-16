# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions
  describe Heartbeat do
    before(:each) do
      @heartbeats = mock('heartbeats')
      @heartbeats.extend Heartbeat
    end
    
    describe "Shared default interface" do
      it "should be dead? when it is not alive?" do
        @heartbeats.stub(:alive? => true)
        @heartbeats.dead?.should be_false

        @heartbeats.stub(:alive? => false)
        @heartbeats.dead?.should be_true
      end

      it "should do nothing when :beat is called" do
        @heartbeats.beat.should be_nil
      end

      it "should be alive if the connection is connected?" do
        @heartbeats.should_receive(:connected?).and_return(true)
        @heartbeats.alive?.should be_true
        @heartbeats.should_receive(:connected?).and_return(false)
        @heartbeats.alive?.should be_false
      end
    end
    
    describe "1.1 Protocol Extensions" do
      before(:each) do
        Heartbeat.extend_by_protocol_version(@heartbeats, '1.1')
      end
      
      it "should include the 1.1 extensions" do
        @heartbeats.should be_a_kind_of(Heartbeat::V1_1)
      end
      
      it "should transmit a heartbeat frame through :beat" do
        @heartbeats.should_receive(:transmit).with(stomper_heartbeat_frame)
        @heartbeats.beat
      end

      it "should be alive if client and broker are alive and connected" do
        @heartbeats.stub(:client_alive? => true, :broker_alive? => true, :connected? => true)
        @heartbeats.alive?.should be_true
        @heartbeats.stub(:connected? => false)
        @heartbeats.alive?.should be_false
      end


      it "should be dead if connected and broker is alive but client is not" do
        @heartbeats.stub(:client_alive? => false, :broker_alive? => true, :connected? => true)
        @heartbeats.alive?.should be_false
        @heartbeats.stub(:client_alive? => true)
        @heartbeats.alive?.should be_true
      end

      it "should be dead if connected and client is alive but broker is not" do
        @heartbeats.stub(:client_alive? => true, :broker_alive? => false, :connected? => true)
        @heartbeats.alive?.should be_false
        @heartbeats.stub(:broker_alive? => true)
        @heartbeats.alive?.should be_true
      end

      it "should have a living client if client beats are disabled" do
        @heartbeats.stub(:heartbeating => [0, 10], :connected? => true)
        @heartbeats.client_alive?.should be_true
      end

      it "should have a living broker if broker beats are disabled" do
        @heartbeats.stub(:heartbeating => [10, 0], :connected? => true)
        @heartbeats.broker_alive?.should be_true
      end

      it "should have a living client if beating is enabled and transmitted within a marin of error" do
        @heartbeats.stub(:heartbeating => [1_000, 0], :connected? => true)
        @heartbeats.stub(:duration_since_transmitted => 50)
        @heartbeats.client_alive?.should be_true
        @heartbeats.stub(:duration_since_transmitted => 1_000)
        @heartbeats.client_alive?.should be_true
        @heartbeats.stub(:duration_since_transmitted => 1_100)
        @heartbeats.client_alive?.should be_true
        @heartbeats.stub(:duration_since_transmitted => 1_200)
        @heartbeats.client_alive?.should be_false
      end

      it "should have a living broker if beating is enabled and received within a marin of error" do
        @heartbeats.stub(:heartbeating => [0, 5_000], :connected? => true)
        @heartbeats.stub(:duration_since_received => 100)
        @heartbeats.broker_alive?.should be_true
        @heartbeats.stub(:duration_since_received => 5_000)
        @heartbeats.broker_alive?.should be_true
        @heartbeats.stub(:duration_since_received => 5_500)
        @heartbeats.broker_alive?.should be_true
        @heartbeats.stub(:duration_since_received => 5_600)
        @heartbeats.broker_alive?.should be_false
      end
    end
  end
end
