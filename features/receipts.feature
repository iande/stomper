Feature: Receipts
  In order to ensure frame delivery
  As a client
  I want to request and monitor RECEIPT frames
  
  Scenario: RECEIPT on SEND
    Given a 1.1 connection between client and broker
    When the client sends a receipted message "test message" to "/queue/test"
    And the frame exchange is completed
    Then the client should have received a receipt for the last "SEND"

  Scenario: RECEIPT on SUBSCRIBE
    Given a 1.1 connection between client and broker
    When the client subscribes to "/queue/test" with a receipt
    And the frame exchange is completed
    Then the client should have received a receipt for the last "SUBSCRIBE"

  Scenario: RECEIPT on UNSUBSCRIBE
    Given a 1.1 connection between client and broker
    And the client subscribes to "/queue/testing" with headers
    | header-name | header-value |
    | id          | s-1234       |
    When the client unsubscribes from "s-1234" with a receipt
    And the frame exchange is completed
    Then the client should have received a receipt for the last "UNSUBSCRIBE"

  Scenario: RECEIPT on BEGIN
    Given a 1.1 connection between client and broker
    When the client begins transaction "t-1234" with a receipt
    And the frame exchange is completed
    Then the client should have received a receipt for the last "BEGIN"

  Scenario: RECEIPT on COMMIT
    Given a 1.1 connection between client and broker
    When the client commits transaction "t-1234" with a receipt
    And the frame exchange is completed
    Then the client should have received a receipt for the last "COMMIT"
  
  Scenario: RECEIPT on ABORT
    Given a 1.1 connection between client and broker
    When the client aborts transaction "t-1234" with a receipt
    And the frame exchange is completed
    Then the client should have received a receipt for the last "ABORT"

  Scenario: RECEIPT on ACK
    Given a 1.1 connection between client and broker
    When the client acks message "m-1234" from "s-5678" with a receipt
    And the frame exchange is completed
    Then the client should have received a receipt for the last "ACK"

  Scenario: RECEIPT on NACK
    Given a 1.1 connection between client and broker
    When the client nacks message "m-1234" from "s-5678" with a receipt
    And the frame exchange is completed
    Then the client should have received a receipt for the last "NACK"
    
  Scenario: RECEIPT on DISCONNECT
    Given a 1.1 connection between client and broker
    When the client disconnects with a receipt
    And the frame exchange is completed without client disconnect
    Then the client should have received a receipt for the last "DISCONNECT"
    
  Scenario: No RECEIPT header on CONNECT
    Given a 1.1 connection between client and broker
    When the client connects with a receipt
    And the frame exchange is completed
    Then the client should not have added a receipt header to the last "CONNECT"
  
  
  

  
