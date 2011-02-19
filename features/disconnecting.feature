Feature: Disconnecting
  In order to shut down a connection
  As a client
  I want to be able to disconnect
  
  
  Scenario: A standard disconnect
    Given a Stomp broker
    And an established connection
    When the client disconnects
    Then the client should not be connected
    And the broker should have received a "DISCONNECT" frame
