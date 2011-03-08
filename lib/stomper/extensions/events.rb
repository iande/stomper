# -*- encoding: utf-8 -*-

# Module for event based extensions.
module Stomper::Extensions::Events
  # A mapping of event names that are just aliases for other event names.
  ALIASED_EVENTS = {
    :on_stomp => :on_connect,
    :before_stomp => :before_connect,
    :on_connection_disconnected => :on_connection_closed
  }
  
  # Register a callback to be fired when an ABORT frame is sent to the broker.
  # @return [self]
  def on_abort(&block); bind_callback(:on_abort, block); end
  # Register a callback to be fired before an ABORT frame is sent to the broker.
  # @return [self]
  def before_abort(&block); bind_callback(:before_abort, block); end
  
  # Register a callback to be fired when an ACK frame is sent to the broker.
  # @return [self]
  def on_ack(&block); bind_callback(:on_ack, block); end
  # Register a callback to be fired before an ACK frame is sent to the broker.
  # @return [self]
  def before_ack(&block); bind_callback(:before_ack, block); end
  
  # Register a callback to be fired when a BEGIN frame is sent to the broker.
  # @return [self]
  def on_begin(&block); bind_callback(:on_begin, block); end
  # Register a callback to be fired before a BEGIN frame is sent to the broker.
  # @return [self]
  def before_begin(&block); bind_callback(:before_begin, block); end
  
  # Register a callback to be fired when a COMMIT frame is sent to the broker.
  # @return [self]
  def on_commit(&block); bind_callback(:on_commit, block); end
  # Register a callback to be fired before a COMMIT frame is sent to the broker.
  # @return [self]
  def before_commit(&block); bind_callback(:before_commit, block); end
  
  # Register a callback to be fired when a CONNECT frame is sent to the broker.
  # @return [self]
  def on_connect(&block); bind_callback(:on_connect, block); end
  # Register a callback to be fired before a CONNECT frame is sent to the broker.
  # @return [self]
  def before_connect(&block); bind_callback(:before_connect, block); end
  alias :on_stomp :on_connect
  alias :before_stomp :before_connect
  
  # Register a callback to be fired when a CONNECTED frame is received from the broker.
  # @return [self]
  def on_connected(&block); bind_callback(:on_connected, block); end
  
  # Register a callback to be fired when a DISCONNECT frame is sent to the broker.
  # @return [self]
  def on_disconnect(&block); bind_callback(:on_disconnect, block); end
  # Register a callback to be fired before a DISCONNECT frame is sent to the broker.
  # @return [self]
  def before_disconnect(&block); bind_callback(:before_disconnect, block); end
  
  # Register a callback to be fired when an ERROR frame is received from the broker.
  # @return [self]
  def on_error(&block); bind_callback(:on_error, block); end
  
  # Register a callback to be fired when a MESSAGE frame is received from the broker.
  # @return [self]
  def on_message(&block); bind_callback(:on_message, block); end
  
  # Register a callback to be fired when a NACK frame is sent to the broker.
  # @return [self]
  def on_nack(&block); bind_callback(:on_nack, block); end
  # Register a callback to be fired before a NACK frame is sent to the broker.
  # @return [self]
  def before_nack(&block); bind_callback(:before_nack, block); end
  
  # Register a callback to be fired when a RECEIPT frame is received from the broker.
  # @return [self]
  def on_receipt(&block); bind_callback(:on_receipt, block); end
  
  # Register a callback to be fired when a SEND frame is sent to the broker.
  # @return [self]
  def on_send(&block); bind_callback(:on_send, block); end
  # Register a callback to be fired before a SEND frame is sent to the broker.
  # @return [self]
  def before_send(&block); bind_callback(:before_send, block); end
  
  # Register a callback to be fired when a SUBSCRIBE frame is sent to the broker.
  # @return [self]
  def on_subscribe(&block); bind_callback(:on_subscribe, block); end
  # Register a callback to be fired before a SUBSCRIBE frame is sent to the broker.
  # @return [self]
  def before_subscribe(&block); bind_callback(:before_subscribe, block); end
  
  # Register a callback to be fired when an UNSUBSCRIBE frame is sent to the broker.
  # @return [self]
  def on_unsubscribe(&block); bind_callback(:on_unsubscribe, block); end
  # Register a callback to be fired before an UNSUBSCRIBE frame is sent to the broker.
  # @return [self]
  def before_unsubscribe(&block); bind_callback(:before_unsubscribe, block); end
  
  # Register a callback to be fired when a heartbeat is sent to the broker.
  # @return [self]
  def on_client_beat(&block); bind_callback(:on_client_beat, block); end
  # Register a callback to be fired before a heartbeat frame is sent to the broker.
  # @return [self]
  def before_client_beat(&block); bind_callback(:before_client_beat, block); end
  
  # Register a callback to be fired when a heartbeat is received from the
  # broker.
  # @return [self]
  def on_broker_beat(&block); bind_callback(:on_broker_beat, block); end

  # Register a callback to be fired when a connection to the broker has
  # been fully established. The connection is fully established once the
  # client has sent a CONNECT frame, the broker has replied with CONNECTED
  # and protocol versions and heartbeat strategies have been negotiated (if
  # applicable.)
  # @return [self]
  def on_connection_established(&block); bind_callback(:on_connection_established, block); end
  
  # Register a callback to be fired when a connection to the broker has
  # been closed. This event will be triggered by
  # {Stomper::Connection#disconnect} as well as any IO exception that shuts
  # the connection down.  In the event that the socket closes unexpectedly,
  # {#on_connection_terminated} will be triggered before this event.
  # @see #on_connection_terminated
  # @return [self]
  def on_connection_closed(&block); bind_callback(:on_connection_closed, block); end
  alias :on_connection_disconnected :on_connection_closed
  
  # Register a callback to be fired when a connection to the broker has
  # died as per the negotiated heartbeat strategy. This event is triggered
  # through {Stomper::Connection#transmit} and {Stomper::Connection#receive}
  # when heartbeat death has been detected. You should not expect this event
  # to trigger at the precise moment the heartbeat strategy failed.
  # @note This event is not triggered the moment heartbeat death occurs.
  # @return [self]
  def on_connection_died(&block); bind_callback(:on_connection_died, block); end
  
  # Register a callback to be fired when a connection to the broker has
  # been unexpectedly terminated. This event will NOT be triggered by
  # {Stomper::Connection#disconnect}.
  # @see #on_connection_closed
  # @return [self]
  def on_connection_terminated(&block); bind_callback(:on_connection_terminated, block); end
  
  # Register a callback to be fired before transmitting any frame. If the
  # supplied block makes any changes to the frame argument, those changes
  # will be sent to the remaining #before_transmitting callbacks, and 
  # ultimately will be passed on to the broker. This provides a convenient
  # way to modify frames before transmission without having to subclass or
  # otherwise extend the {Stomper::Connection} class. Furhter,
  # changing the {Stomper::Frame#command command} attribute of the frame
  # will change the frame-specific event that is triggered.
  # @return [self]
  def before_transmitting(&block); bind_callback(:before_transmitting, block); end
  
  # Register a callback to be fired after transmitting any frame.
  # Changes made to the frame object will be passed along to all remaining
  # {#after_transmitting} callbacks. Furhter,
  # changing the {Stomper::Frame#command command} attribute of the frame
  # will change the frame-specific event that is triggered.
  # @return [self]
  def after_transmitting(&block); bind_callback(:after_transmitting, block); end
  
  # Register a callback to be fired before receiving any frame. As a frame
  # has not yet been received, callbacks invoked on this event will have
  # to work with very limited information.
  # @return [self]
  def before_receiving(&block); bind_callback(:before_receiving, block); end
  
  # Register a callback to be fired after receiving any frame. Like
  # the #before_transmitting event, any changes made to the frame will be
  # passed along to all remaining {#after_receiving} callbacks. Furhter,
  # changing the {Stomper::Frame#command command} attribute of the frame
  # will change the frame-specific event that is triggered.
  # @return [self]
  def after_receiving(&block); bind_callback(:after_receiving, block); end
  
  # Binds a +Proc+ to be invoked when the given +event_name+ is triggered.
  # @param [Symbol] event_name
  # @param [Proc] cb_proc
  # @return [self]
  def bind_callback(event_name, cb_proc)
    @event_callbacks ||= {}
    @event_callbacks[event_name] ||= []
    @event_callbacks[event_name] << cb_proc
    self
  end
  
  def trigger_event(event_name, *args)
    event_name = ALIASED_EVENTS[event_name] ? ALIASED_EVENTS[event_name] : event_name
    @event_callbacks && @event_callbacks[event_name] &&
      @event_callbacks[event_name].each { |cb| cb.call(*args) }
  end
  private :trigger_event
  
  def trigger_received_frame(frame, *args); trigger_frame(frame, :on, :on_broker_beat, args); end
  private :trigger_received_frame
  
  def trigger_transmitted_frame(frame, *args); trigger_frame(frame, :on, :on_client_beat, args); end
  private :trigger_transmitted_frame
  
  def trigger_before_transmitted_frame(frame, *args); trigger_frame(frame, :before, :before_client_beat, args); end
  private :trigger_before_transmitted_frame
  
  def trigger_frame(frame, timing, beat_event, args)
    if (f_comm = frame.command && frame.command.downcase.to_sym)
      trigger_event(:"#{timing}_#{f_comm}", frame, *args)
    else
      trigger_event(beat_event, frame, *args)
    end
  end
  private :trigger_frame
end
