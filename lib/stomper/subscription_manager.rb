# -*- encoding: utf-8 -*-

# Manages subscriptions for a {Stomper::Connection}
class Stomper::SubscriptionManager
  # Creates a new subscription handler for the supplied {Stomper::Connection connection}
  # @param [Stomper::Connection] connection
  def initialize(connection)
    connection.on_message { |m| dispatch(m) }
  end
  
  def dispatch(message)
  end
end
