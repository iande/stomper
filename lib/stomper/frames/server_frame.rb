module Stomper
  module Frames
    # Encapsulates a server side frame for the Stomp Protocol.
    #
    # See the {Stomp Protocol Specification}[http://stomp.codehaus.org/Protocol]
    # for more details.
    class ServerFrame
      attr_reader :command, :headers, :body

      # Creates a new server frame corresponding to the
      # supplied +command+ with the given +headers+ and +body+.
      def initialize(command, headers={}, body=nil)
        @command = command
        @headers = headers.dup
        @body = body
      end

      class << self
        # Provides a method for subclasses to register themselves
        # as factories for particular stomp commands by passing a list
        # of strings (or symbols) to this method.  Each element in
        # the list is interpretted as the command for which we will
        # defer to the calling subclass to build.
        def factory_for(*args)
          @@registered_commands ||= {}
          args.each do |command|
            @@registered_commands[command.to_s.upcase] = self
          end
        end

        # Builds a new ServerFrame instance by first checking to
        # see if some subclass of ServerFrame has registered itself
        # as a builder of the particular command.  If so, a new
        # instance of that subclass is created, otherwise a generic
        # ServerFrame instance is created with its +command+ attribute
        # set appropriately.
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
