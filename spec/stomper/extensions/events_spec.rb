# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions
  describe Events do
    before(:each) do
      @events = mock('events')
      @events.extend Events
    end
    
    describe "basic event callbacks" do
      [:on_abort, :on_ack, :on_begin, :on_commit, :on_connect, :on_stomp,
        :on_connected, :on_disconnect, :on_error, :on_message, :on_nack,
        :on_receipt, :on_send, :on_subscribe, :on_unsubscribe, :on_client_beat,
        :on_broker_beat, :on_connection_established, :on_connection_closed,
        :on_connection_terminated, :on_connection_disconnected,
        :on_connection_died, :before_transmitting, :after_transmitting,
        :before_receiving, :after_receiving].each do |event_name|
        
        it "should register a callback for #{event_name} and trigger appropriately" do
          triggered = false
          @events.__send__(event_name) do
            triggered = true
          end
          @events.__send__(:trigger_event, event_name)
          triggered.should be_true
        end
      end
    end
    
    describe "frame event callbacks" do
      [ :on_connected, :on_error, :on_message, :on_receipt].each do |event_name|

        it "should register a callback for #{event_name} and trigger when the frame is received" do
          command_name = event_name.to_s.split('_').last.upcase
          triggered = false
          @events.__send__(event_name) do
            triggered = true
          end
          @events.__send__(:trigger_received_frame, ::Stomper::Frame.new(command_name))
          triggered.should be_true
        end
      end
      
      [:on_abort, :on_ack, :on_begin, :on_commit, :on_connect, :on_stomp,
        :on_disconnect, :on_nack, :on_send, :on_subscribe, :on_unsubscribe].each do |event_name|

        it "should register a callback for #{event_name} and trigger when the frame is transmitted" do
          command_name = event_name.to_s.split('_').last.upcase
          triggered = false
          @events.__send__(event_name) do
            triggered = true
          end
          @events.__send__(:trigger_transmitted_frame, ::Stomper::Frame.new(command_name))
          triggered.should be_true
        end
      end
      
      it "should trigger a broker beat when receiving a frame with no command" do
        triggered = false
        @events.on_broker_beat do
          triggered = true
        end
        @events.__send__(:trigger_received_frame, ::Stomper::Frame.new)
        triggered.should be_true
      end
      
      it "should trigger a client beat when receiving a frame with no command" do
        triggered = false
        @events.on_client_beat do
          triggered = true
        end
        @events.__send__(:trigger_transmitted_frame, ::Stomper::Frame.new)
        triggered.should be_true
      end
    end
  end
end
