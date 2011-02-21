Feature: Scopes
  In order to apply similar behavior to a series of frames
  As a client
  I want to have frame scopes

  Scenario: Applying a set of headers to a series of frames
    Given a 1.1 connection between client and broker
    And a header scope with headers
    | header-name   | header-value |
    | x-my-header   | some value   |
    | canon:unisono | violini      |
    | x-machine     | a\b\c        |
    When the client acks a message by ID "m-1234" and subscription "s-5678" within the scope
    And the client subscribes to "/topic/test" with headers within the scope
    | header-name | header-value      |
    | id          | s-9012            |
    | ack         | client-individual |
    Then the broker should have received an "ACK" frame with headers
    | header-name   | header-value |
    | x-my-header   | some value   |
    | canon:unisono | violini      |
    | x-machine     | a\b\c        |
    | message-id    | m-1234       |
    | subscription  | s-5678       |
    And the broker should have received a "SUBSCRIBE" frame with headers
    | header-name   | header-value      |
    | x-my-header   | some value        |
    | canon:unisono | violini           |
    | x-machine     | a\b\c             |
    | id            | s-9012            |
    | destination   | /topic/test       |
    | ack           | client-individual |
