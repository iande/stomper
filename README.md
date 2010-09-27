#README

Stomper is a library for connecting to and interacting with a message broker
service that supports the Stomp 1.0 Protocol

See: [Stomp 1.0 Specification](http://stomp.github.com/stomp-specification-1-0.html)


## OpenURI Example Usage

    # A contrived example: Send two messages, receive them back
    open("stomp://localhost/queue/testing") do |s|
      s.puts "Hello World"
      s.write "You may disagree, but I find this useful!"
      messages = s.first(2) # => [ Message("Hello World"), Message("You may disagree...") ]
    end

    # Another example: connect, send a message to a destination and disconnect
    open("stomp://localhost/topic/whatever") do |s|
      s.put "PING!"
    end

    # Another example: connect, subscribe and process indefinitely
    open("stomp://localhost/queue/worker") do |s|
      s.each do |m|
        logger.info "Received a message: #{m.body}"
        # Do important work based on message
      end
    end

    # Final example: connect, get a single message, and disconnect
    open("stomp+ssl://localhost/queue/odd_jobs") do |s|
      # you can use get, gets, read or first, they're all the same at
      # this time and for the foreseeable future.
      incoming_message = s.get
      # Do some work on incoming_message
    end

This interface has been a goal of mine for this library for some time now.  I
understand the value in a more typical socket object approach, and to that end
the client interface still exists (albeit there's been quite a lot of refractoring.)
However,

    stomp = Stomper::Connection.new("stomp://localhost/")
    stomp.subscribe("/queue/blather") do |m|
      # ...
    end
    stomp.send("/topic/other", "Hello")

just doesn't feel very Ruby-esque to me.  While the two methods for interacting with
Stomper connections appear very different, +s+ in the OpenURI examples above
really is a Stomper::Connection, but with some added extensions for handling
+put+, +get+, +each+, and so forth.  One note: +read+, +get+ and +gets+ are
all aliases for +first+.  Similarly, +puts+ is an alias for +put+.  However,
+write+ is slightly different.  The message broker I most often use the
STOMP protocol with is Apache ActiveMQ which, at the time of this writing, uses
the absence or presence of a `content-length` header to discriminate between a
JMS TextMessage and a BytesMessage.  The +put+ and +puts+ methods will force
Stomper to omit that header, while +write+ will force its presence.

## Example Usage

    client = Stomper::Client.new("stomp://my_username:s3cr3tz@localhost:61613")
    # Clients must be explicitly started to automatically receive incoming
    # messages.
    client.start

    client.subscribe("/queue/hello") do |msg|
      puts msg.body
    end

    # Send a simple message
    client.send("/queue/hello", "hello world!")

    # Send a message within a transaction.  This usage is new to stomper
    # however, one can manually manage transactions as well.
    client.transaction do |t|
      t.send("/queue/hello", "a transactioned message")
    end

    # If the block provided to #transaction accepts a single parameter,
    # the client yields the Transaction object to the block, otherwise
    # the block is instance_eval'd within the Transaction object.
    client.transaction do
      send("/queue/hello", "a message you will never receive")
      # Nested transactions, failures percolate up to parent transactions.
      transaction do
        send("/queue/hello", "because I am about to fail!")
        raise "by forcing an error in a nested transaction"
      end
    end

    # Later ...
    client.stop
    client.close

## To-Do
* Provide other methods for handling the receiver.
* Provide the `pipe` method on Stomper::Client
* Allow SSL verification if requested (option :verify_ssl?)
* Re-evaluate how to handle a 'reliable' connection.

## License

Stomper is released under the Apache License 2.0

## Pointless Backstory

Stomper began its life as a mere fork of the stomp gem.
However, as changes were made and desires grew, the fork began breaking
API compatibility with the original gem, and thus Stomper was conceived.

See: [stomp gem](http://github.com/js/stomp)

## Other Stuff

Primary Author:: Ian D. Eccles
Source Repository:: http://github.com/iande/stomper
Current Version:: 1.0.0
Last Updated:: 2010-09-25