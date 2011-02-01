# -*- encoding: utf-8 -*-
module Stomper
  module Errors
    # A common base class for errors raised by the Stomper gem
    #
    # @abstract
    class StomperError < StandardError; end
    
    # Raised when an invalid header key is specified in a frame
    class InvalidHeaderKey < StomperError; end
    
  end
end
