Feature: Establish connection
  In order to actually do something useful with a Stomp broker
  As a client
  I want to be able to connect
  
  Scenario: Connecting to a Stomp 1.0 Broker
    Given a Stomp 1.0 broker
    When a connection is created from the broker's URI
    And the connection is told to connect
    Then the connection should be connected
    And the connection should be using the 1.0 protocol

  Scenario: Connecting to a Stomp 1.0 Broker by string
    Given a Stomp 1.0 broker
    When a connection is created from the broker's URI string
    And the connection is told to connect
    Then the connection should be connected
    And the connection should be using the 1.0 protocol

  Scenario: Connecting to a Stomp 1.1 Broker
    Given a Stomp 1.1 broker
    When a connection is created from the broker's URI
    And the connection is told to connect
    Then the connection should be connected
    And the connection should be using the 1.1 protocol
        
  Scenario: Connecting to a Stomp 1.1 Broker by string
    Given a Stomp 1.1 broker
    When a connection is created from the broker's URI string
    And the connection is told to connect
    Then the connection should be connected
    And the connection should be using the 1.1 protocol
    
  Scenario: Connecting to a Broker using an unsupported version
    Given a Stomp 3.2 broker
    When a connection is created from the broker's URI
    Then connecting should raise an unsupported protocol version error
    And the connection should not be connected

  Scenario: Connecting to a Broker whose first frame is not CONNECTED
    Given an erroring Stomp broker
    When a connection is created from the broker's URI
    Then connecting should raise an connect failed error
    And the connection should not be connected
