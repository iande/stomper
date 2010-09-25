module Stomper
  module Frames
    # Encapsulates a server side frame for the Stomp Protocol.
    class ServerFrame < IndirectFrame

      # Creates a new server frame corresponding to the
      # supplied +command+ with the given +headers+ and +body+.
      def initialize(headers={}, body=nil, command = nil)
        super
      end

      class << self
        def inherited(server_frame) #:nodoc:
          declared_frames << { :class => server_frame, :command => server_frame.name.split("::").last.downcase.to_sym }
        end

        def declared_frames
          @declared_frames ||= []
        end

        # Builds a new ServerFrame instance by first checking to
        # see if some subclass of ServerFrame has registered itself
        # as a builder of the particular command.  If so, a new
        # instance of that subclass is created, otherwise a generic
        # ServerFrame instance is created with its +command+ attribute
        # set appropriately.
        def build(command, headers, body)
          com_sym = command.downcase.to_sym
          if klass = declared_frames.detect { |frame| com_sym == frame[:command] }
            klass[:class].new(headers, body)
          else
            ServerFrame.new(headers, body, command)
          end
        end
      end
    end
  end
end
