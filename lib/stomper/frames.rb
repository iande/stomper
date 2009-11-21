module Stomper
  module Frames
    def parse_command_name(clazz)
      clazz.to_s.split("::").last
    end
    module_function :parse_command_name
  end
end

require 'stomper/frames/headers'
require 'stomper/frames/client_frame'
require 'stomper/frames/server_frame'
require 'stomper/frames/abort'
require 'stomper/frames/ack'
require 'stomper/frames/begin'
require 'stomper/frames/commit'
require 'stomper/frames/connect'
require 'stomper/frames/connected'
require 'stomper/frames/disconnect'
require 'stomper/frames/error'
require 'stomper/frames/message'
require 'stomper/frames/receipt'
require 'stomper/frames/send'
require 'stomper/frames/subscribe'
require 'stomper/frames/unsubscribe'
