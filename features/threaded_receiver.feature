Feature: Threaded receiver
  In order receive frames asynchronously
  As a client
  I want a threaded receiver
  
  Scenario: receiver is no longer running when an exception is raised by receive
    Given a 1.1 connection between client and broker
    When the broker closes the connection unexpectedly
    Then the receiver should no longer be running
    And the connection should not be connected

