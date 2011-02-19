Feature: Subscribing
  In order retrieve MESSAGEs from a broker
  As a client
  I want to be able to subscribe to destinations
  
  
  Scenario: Delivering MESSAGE frames with subscription ID
    Given a 1.1 connection between client and broker
    When the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-5678       |
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1235         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    And the frame exchange is completed
    Then the client should have received a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    And the client should have received a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1235         |
    | subscription | s-5678         |
    | destination  | /queue/testing |
    And the default subscription callback should have been triggered 2 times
  
  
  Scenario: Delivering MESSAGE frames without subscription ID
    Given a 1.1 connection between client and broker
    When the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-5678       |
    And the broker sends a "MESSAGE" frame with headers
    | header-name | header-value   |
    | message-id  | m-1234         |
    | destination | /queue/testing |
    And the broker sends a "MESSAGE" frame with headers
    | header-name | header-value   |
    | message-id  | m-1235         |
    | destination | /queue/testing |
    And the broker sends a "MESSAGE" frame with headers
    | header-name | header-value   |
    | message-id  | m-1236         |
    | destination | /queue/testing |
    And the frame exchange is completed
    Then the client should have received a "MESSAGE" frame with headers
    | header-name | header-value |
    | message-id  | m-1234       |
    And the client should have received a "MESSAGE" frame with headers
    | header-name | header-value |
    | message-id  | m-1235       |
    And the client should have received a "MESSAGE" frame with headers
    | header-name | header-value |
    | message-id  | m-1236       |
    And the default subscription callback should have been triggered 3 times
    
    
  Scenario: No callbacks for MESSAGE frames for which we have not subscribed
    Given a 1.1 connection between client and broker
    When the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-5678       |
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | destination  | /queue/testing |
    | subscription | s-9999         |
    And the frame exchange is completed
    Then the client should have received a "MESSAGE" frame with headers
    | header-name  | header-value |
    | subscription | s-9999       |
    | message-id   | m-1234       |
    And the default subscription callback should not have been triggered
  
  
  Scenario: No callbacks after unsubscribing by ID
    Given a 1.1 connection between client and broker
    When the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-5678       |
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | destination  | /queue/testing |
    | subscription | s-5678         |
    And the client unsubscribes by ID
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1235         |
    | destination  | /queue/testing |
    | subscription | s-5678         |
    And the client disconnects
    Then the default subscription callback should have been triggered 1 time

  Scenario: No callbacks after unsubscribing by frame
    Given a 1.1 connection between client and broker
    When the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-5678       |
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | destination  | /queue/testing |
    | subscription | s-5678         |
    And the client unsubscribes by frame
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1235         |
    | destination  | /queue/testing |
    | subscription | s-5678         |
    And the frame exchange is completed
    Then the default subscription callback should have been triggered 1 time

  Scenario: Unsubscribing from many by destination
    Given a 1.1 connection between client and broker
    When the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-5678       |
    And the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-5679       |
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1234         |
    | destination  | /queue/testing |
    | subscription | s-5678         |
    And the broker sends a "MESSAGE" frame with headers
    | header-name  | header-value   |
    | message-id   | m-1235         |
    | destination  | /queue/testing |
    And the client unsubscribes from destination "/queue/testing"
    And the broker sends a "MESSAGE" frame with headers
    | header-name | header-value   |
    | message-id  | m-1235         |
    | destination | /queue/testing |
    And the frame exchange is completed
    Then the default subscription callback should have been triggered 3 times
    And the broker should have received an "UNSUBSCRIBE" frame with headers
    | header-name | header-value |
    | id          | s-5678       |
    And the broker should have received an "UNSUBSCRIBE" frame with headers
    | header-name | header-value |
    | id          | s-5679       |
