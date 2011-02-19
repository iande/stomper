Feature: Send and message
  In order exchange information
  As a client
  I want to be able to transmit SEND and receive MESSAGE frames
  
  Scenario Outline: sending and receiving messages with content-types
    Given a 1.1 connection between client and broker
    And the client subscribes to <destination>
    When the client sends a <content-type> <body> to <destination>
    And the frame exchange is completed
    Then the client should have received a <content-type> message of <body>
    
    Examples:
      | destination  | content-type      | body          |
      | /queue/test1 | "text/plain"      | "hello world" |
      | /queue/test2 | "application/xml" | "<xml></xml>" |

  Scenario Outline: sending and receiving messages with encodings
    Given a 1.1 connection between client and broker
    And the client subscribes to <destination>
    When the client sends a <body> encoded as <encoding> to <destination>
    And the frame exchange is completed
    Then the client should have received a <content-type> message of <body> encoded as <final encoding>

    Examples:
      | destination  | content-type               | body          | encoding     | final encoding |
      | /queue/test1 | "text/plain"               | "hello world" | "UTF-8"      | "UTF-8"        |
      | /queue/test2 | "application/octet-stream" | "hello world" | "ASCII-8BIT" | "US-ASCII"     |
