Feature: Secure connections
  In order connect to an SSL protected broker
  As a client
  I want secure connections

  Scenario: SSL connection without verifying broker
    Given a Stomp 1.1 SSL broker
    When a connection is created for the SSL broker
    And no SSL verification is performed
    And an SSL post connection check is not performed
    And the connection is told to connect
    Then the connection should be connected
  
  Scenario: SSL connection verifying hostname
    Given a Stomp 1.1 SSL broker
    When a connection is created for the SSL broker
    And no SSL verification is performed
    And an SSL post connection check is performed on "My Broker"
    And the connection is told to connect
    Then the connection should be connected

  Scenario: SSL connection verifying hostname failure
    Given a Stomp 1.1 SSL broker
    When a connection is created for the SSL broker
    And the broker's host is "My Broker"
    And no SSL verification is performed
    And an SSL post connection check is performed on "Some Other Common Name"
    Then connecting should raise an openssl error

  Scenario: SSL broker certificate verification
    Given a Stomp 1.1 SSL broker
    When a connection is created for the SSL broker
    And the broker's host is "My Broker"
    And an SSL post connection check is performed on "My Broker"
    And the broker's certificate is verified by CA
    And SSL verification is performed
    And the connection is told to connect
    Then the connection should be connected
