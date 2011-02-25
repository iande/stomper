Feature: Acking messages
  In order inform the broker that we have received and processed a MESSAGE
  As a client
  I want ensure ACK frames are properly sent
  
  Scenario: Stomp 1.0 Acking a MESSAGE
    Given a 1.0 connection between client and broker
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    #When the client waits for 1 "MESSAGE" frame
    When the client acks the last MESSAGE
    And the frame exchange is completed
    Then the broker should have received an "ACK" frame with headers
    | header-name | header-value |
    | message-id  | m-1234       |
  
  Scenario: Stomp 1.0 Acking a MESSAGE by ID
    Given a 1.0 connection between client and broker
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    When the client acks a message by ID "m-1234"
    And the frame exchange is completed
    Then the broker should have received an "ACK" frame with headers
    | header-name | header-value |
    | message-id  | m-1234       |
    
  Scenario: Stomp 1.0 Nacking a MESSAGE
    Given a 1.0 connection between client and broker
    When the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    Then the client nacking the last MESSAGE should raise an unsupported command error
    
    
  Scenario: Stomp 1.1 Acking a MESSAGE
    Given a 1.1 connection between client and broker
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    When the client acks the last MESSAGE
    And the frame exchange is completed
    Then the broker should have received an "ACK" frame with headers
    | header-name  | header-value |
    | message-id   | m-1234       |
    | subscription | s-5678       |

  Scenario: Stomp 1.1 Acking a MESSAGE by ID and subscription
    Given a 1.1 connection between client and broker
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    When the client acks a message by ID "m-1234" and subscription "s-5678"
    And the frame exchange is completed
    Then the broker should have received an "ACK" frame with headers
    | header-name  | header-value |
    | message-id   | m-1234       |
    | subscription | s-5678       |

  Scenario: Stomp 1.1 Nacking a MESSAGE
    Given a 1.1 connection between client and broker
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    When the client nacks the last MESSAGE
    And the frame exchange is completed
    Then the broker should have received a "NACK" frame with headers
    | header-name  | header-value |
    | message-id   | m-1234       |
    | subscription | s-5678       |
  
  Scenario: Stomp 1.1 Nacking a MESSAGE by ID and subscription
    Given a 1.1 connection between client and broker
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    When the client nacks a message by ID "m-1234" and subscription "s-5678"
    And the frame exchange is completed
    Then the broker should have received an "NACK" frame with headers
    | header-name  | header-value |
    | message-id   | m-1234       |
    | subscription | s-5678       |

  Scenario: Stomp 1.1 Acking a MESAGE by ID should raise an error
    Given a 1.1 connection between client and broker
    When the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    Then the client acking a message by ID "m-1234" should raise an argument error
  
  Scenario: Stomp 1.1 Nacking a MESAGE by ID should raise an error
    Given a 1.1 connection between client and broker
    When the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    Then the client nacking a message by ID "m-1234" should raise an argument error
        
  Scenario: Stomp 1.1 Acking a MESAGE without a subscription should raise an error
    Given a 1.1 connection between client and broker
    When the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | destination  | /queue/testing |
    Then the client acking the last MESSAGE should raise an argument error

  Scenario: Stomp 1.1 Nacking a MESAGE without a subscription should raise an error
    Given a 1.1 connection between client and broker
    When the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | destination  | /queue/testing |
    Then the client nacking the last MESSAGE should raise an argument error
    
    Scenario: Stomp 1.1 Acking a MESAGE without a message-id should raise an error
      Given a 1.1 connection between client and broker
      When the broker sends a "MESSAGE" frame with headers
      | header-name  | header-value   |
      | subscription   | s-5678         |
      | destination  | /queue/testing |
      Then the client acking the last MESSAGE should raise an argument error

    Scenario: Stomp 1.1 Nacking a MESAGE without a message-id should raise an error
      Given a 1.1 connection between client and broker
      When the broker sends a "MESSAGE" frame with headers
      | header-name  | header-value   |
      | subscription  | s-5678         |
      | destination  | /queue/testing |
      Then the client nacking the last MESSAGE should raise an argument error

