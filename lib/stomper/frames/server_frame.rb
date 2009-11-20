module Stomper
  module Frames
    class ServerFrame
      attr_reader :command, :headers, :body

      def initialize(command, headers={}, body=nil)
        @command = command
        @headers = headers
        @body = body
      end

      class << self
        def frame_factory(*args)
          @@registered_commands ||= {}
          args.each do |command|
            @@registered_commands[command.to_s.upcase] = self
          end
        end

        def factory_for(command)
          @@registered_commands[command.to_s.upcase]
        end

        def build(command, headers, body)
          command = command.to_s.upcase
          if @@registered_commands.has_key?(command)
            @@registered_commands[command].new(headers, body)
          else
            ServerFrame.new(command, headers, body)
          end
        end
      end
    end
  end
end
