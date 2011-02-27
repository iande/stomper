#Stomper 2.0

Stomper is a library for connecting to and interacting with a message broker
service that supports the Stomp [1.0](http://stomp.github.com/stomp-specification-1-0.html)
and [1.1](http://stomp.github.com/stomp-specification-1-1.html) protocols.  It
was written with Ruby 1.9.2 in mind, but will also work with Ruby 1.8.7, previous
versions of Ruby are not supported.

As the Stomp 1.1 specification is stabilizing, there should not be major
changes to this codebase once all of the features are fully implemented.
There is still a significant amount of work that must be done before this
gem is ready for any use. It can be used right now, but the API will be
rather unpleasant to deal with for common use cases.

This gem is in no way related to the [Python stomper](http://code.google.com/p/stomper/)
library.

##Still in the Works

There are a few features that have not yet been implemented, hence why we're
still on a prerelease version number. The following is a list of the major
deficiencies of the gem, but this list is not necessarily exhaustive.

* Write some features to test other connections:
  * Authenticated logins
  * SSL Client verification (just to ensure that SSL params are being
    delivered appropriately)
* A bit of refactoring is in order
  * Refactor specs a bit, clean up separation between 1.9 and 1.8 specific tests

As these issues are resolved, I'll drop them from the list (and potentially
add other issues)

##Example Usage

    # Establish a connection to the broker
    con = Stomper::Connection.open('stomp://host.example.com')
    
    # Starts a receiver to read frames sent by the broker to the client.
    # By default, this will create a new thread (once it is implemented)
    con.start
    
    # SUBSCRIBE to the '/queue/test' destination
    con.subscribe('/queue/test') do |message|
      con.ack(message)
      puts "Message Received: #{message.body}"
    end
    
    # Deliver a SEND frame to the broker
    con.send("/queue/test", "this is a tribute")
    
    # A transaction in a block
    con.with_transaction do |t|
      t.send("/queue/test2", "first in a transaction")
      t.send("/queue/test2", "second in a transaction")
      # A transaction block is automatically finalized once the block
      # finishes. If no exception is raised within the block, the transaction
      # is committed, otherwise it is aborted.
    end
    
    # A 'free' transaction scope
    trans = con.with_transaction
    
    trans.send("/queue/other", "test message", { :'x-special-header' => 'marked'})
    con.subscribe("/queue/other") do |m|
      # Frame headers can be referenced by Symbol or String
      if m['x-special-header'] == 'marked'
        trans.ack(m)
        # A 'free' transaction scope must be explicitly committed
        trans.commit
      end
    end
    
    # A receipt scope
    con.with_receipt do |r|
      puts "Got receipt for SEND frame"
    end.send("/queue/receipted", "this message will generate a receipt")
    
    # A 'free' receipt scope
    receipter = con.with_receipt { |r| puts "Got a receipt: #{r[:receipt-id]}" }
    
    # Automatically generates a receipt ID.
    receipter.subscribe("/topic/example")
    # Or a receipt ID can be specified with a :receipt header value.
    receipter.send("/queue/receipted", "also generates a receipt", :receipt => 'rcp-1234')
    
    # Listen to some events
    con.on_message do |frame|
      puts "Incoming MESSAGE: #{frame.body}"
    end
    
    con.on_subscribe do |frame|
      puts "Client is subscribing to #{frame[:destination]}"
    end
    
    con.after_transmitting do |frame|
      puts "Client is transmitting #{frame.command}"
    end
    
    con.on_connection_terminated do
      $stderr.puts "Connection terminated abnormally!"
    end

##A Note About Encodings

The Stomp 1.1 specification encourages the use of a content-type header to
indicate both the media type of the body of a frame as well as its character
encoding (if the body is text.)  Stomper, when used with Ruby 1.9, will do
much of the work for you in setting an appropriate charset provided you are
using its Encoding features properly.  Ruby 1.8.7, however, lacks native String
encoding functionality.  As such, it is up to you to set an appropriate charset
parameter for frames that have a body.

Further, frames read from a broker that include a content-type header with a
charset will have their bodies properly encoded in Ruby 1.9.  In Ruby 1.8.7,
a frame's body will always be a string of bytes.

##License

Stomper is released under the Apache License 2.0 by Ian D. Eccles.
See LICENSE for full details.

##Thanks

* Lionel Cons -- Perl STOMP library -- lots of good suggestions and support
  while I revised Stomper to support STOMP 1.1
* Brian McCallister and Johan Sørensen -- [Original STOMP ruby gem](http://gitorious.org/stomp) --
  introduced me to the STOMP spec and started my work on this gem
* Hiram Chino and everyone on the stomp-spec mailing list for keeping the
  Stomp 1.1 spec moving
