# -*- encoding: utf-8 -*-
module RSpec
  module Mocks
    module ArgumentMatchers
      def stomper_frame_with_headers(*args)
        command = args.last.is_a?(String) ? args.pop : nil
        StomperFrameMatcher.new(command, nil, anythingize_lonely_keys(*args))
      end
      
      def stomper_frame_with_body(body, command=nil)
        StomperFrameMatcher.new(command, body, nil)
      end
      
      def stomper_frame(body, *args)
        command = args.last.is_a?(String) ? args.pop : nil
        StomperFrameMatcher.new(command, body, anythingize_lonely_keys(*args))
      end
      
      def stomper_heartbeat_frame
        StomperFrameMatcher.new(nil, nil, {})
      end
      
      class StomperFrameMatcher
        def initialize(e_command, e_body, e_headers)
          @expected_command = e_command && e_command.upcase
          @expected_body = e_body
          @expected_headers = e_headers
        end
        
        def ==(actual)
          if @expected_command
            return false unless @expected_command == actual.command
          end
          if @expected_body
            return false unless @expected_body == actual.body
          end
          if @expected_headers
            @expected_headers.each do |key, val|
              return false unless actual[key] == val.to_s
            end
          end
          true
        rescue NoMethodError => ex
          return false
        end
        
        def description
          frame_name = @expected_command || 'Any frame'
          with_headers = @expected_headers ? "with headers (#{@expected_headers.inspect.sub(/^\{/,"").sub(/\}$/,"")})" : nil
          with_body = @expected_body ? "with body (#{@expected_body})" : nil
          additional_desc = [with_headers, with_body].compact.join(' and ')
          "#{frame_name} #{additional_desc}"
        end
      end
    end
  end
end
