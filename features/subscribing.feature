Feature: Subscribing and unsubscribing from a Stomp Message Broker.
  In order to filter and participate in message passing
  As a consuming Stomper connection
  I want to be able to subscribe and unsubscribe from specific destinations.

  Scenario: Basic subscription to a queue
    Given I am connected to "stomp:///"
      And I am subscribed to "/queue/test/alpha"
      And a producer exists for "stomp:///"
     When a producer sends "test message" to "/queue/test/alpha"
      And I receive a frame
     Then the frame's headers should include "destination" paired with "/queue/test/alpha"
      And the frame's body should be "test message"
