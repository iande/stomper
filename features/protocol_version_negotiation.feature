Feature: Protocol version negotiation
  In order to handle connecting to different Stomp protocol implementations
  As a client
  I want to be able to negotiate the Stomp protocol to use
  
  Scenario: By default, allow 1.1 from broker
    Given a Stomp 1.1 broker
    When the connection is told to connect
    Then the connection should be using the 1.1 protocol
    
  Scenario: By default, allow 1.0 from broker
    Given a Stomp 1.0 broker
    When the connection is told to connect
    Then the connection should be using the 1.0 protocol
    
  Scenario: By default, assume 1.0 from version-less broker
    Given an unversioned Stomp broker
    When the connection is told to connect
    Then the connection should be using the 1.0 protocol
  
  Scenario: By default, raise error if the broker's version isn't supported
    Given a Stomp 2.1 broker
    When a connection is created from the broker's URI
    Then connecting should raise an unsupported protocol version error
  
  Scenario: A 1.0 client should accept a 1.0 broker
    Given a Stomp 1.0 broker
    When the client protocol version is "1.0"
    And the connection is told to connect
    Then the connection should be using the 1.0 protocol
  
  Scenario: A 1.0 client should accept a version-less broker
    Given an unversioned Stomp broker
    When the client protocol version is "1.0"
    And the connection is told to connect
    Then the connection should be using the 1.0 protocol
    
  Scenario: A 1.0 client should not accept a 1.1 broker
    Given a Stomp 1.1 broker
    When the client protocol version is "1.0"
    And a connection is created from the broker's URI
    Then connecting should raise an unsupported protocol version error
    
  Scenario: A 1.1 client should accept a 1.1 broker
    Given a Stomp 1.1 broker
    When the client protocol version is "1.1"
    And the connection is told to connect
    Then the connection should be using the 1.1 protocol
  
  Scenario: A 1.1 client should not accept a 1.0 broker
    Given a Stomp 1.0 broker
    When the client protocol version is "1.1"
    And a connection is created from the broker's URI
    Then connecting should raise an unsupported protocol version error

  Scenario: A 1.1 client should not accept a version-less broker
    Given an unversioned Stomp broker
    When the client protocol version is "1.1"
    And a connection is created from the broker's URI
    Then connecting should raise an unsupported protocol version error
  
