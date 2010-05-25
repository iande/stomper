Feature: Transactional messaging
  In order to ensure atomicity of messages
  As a consuming Stomper connection
  I want to be able to ensure transactional integrity of messages

  Scenario: Aborted transactions are not delivered
    Given I am connected to "stomp:///"
      And I am subscribed to "/queue/test/trans/alpha"
      And a producer exists for "stomp:///"
    When the producer aborts "failed message" to "/queue/test/trans/alpha"
     And the producer commits "sent message" to "/queue/test/trans/alpha"
     And I receive a frame
    Then the frame's headers should include "destination" paired with "/queue/test/trans/alpha"
     And the frame's body should be "sent message"

  Scenario: Exceptions raised within transactions are not delivered
    Given I am connected to "stomp:///"
      And I am subscribed to "/queue/test/trans/beta"
      And a producer exists for "stomp:///"
    When the producer creates an exception while sending "exceptional message" to "/queue/test/trans/beta"
     And the producer commits "unexceptional message" to "/queue/test/trans/beta"
     And I receive a frame
    Then the frame's headers should include "destination" paired with "/queue/test/trans/beta"
     And the frame's body should be "unexceptional message"
