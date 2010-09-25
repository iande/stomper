require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
module Stomper
  module Frames
    describe IndirectFrame do
      describe "interface" do
        before(:each) do
          @indirect_frame = IndirectFrame.new({}, nil, "INDIRECT_COMMAND")
        end

        it "should provide a command attribute" do
          @indirect_frame.should respond_to(:command)
        end
        it "should provide a body attribute" do
          @indirect_frame.should respond_to(:body)
        end
        it "should provide a headers attribute" do
          @indirect_frame.should respond_to(:headers)
        end
      end

      describe "command name" do
        class UnnamedIndirectFrame < IndirectFrame; end
        class NamedIndirectFrame < IndirectFrame
          def initialize
            super({}, nil, :test_command)
          end
        end

        it "should use its class name if no command is specified" do
          @indirect_frame = IndirectFrame.new({}, nil)
          @indirect_frame.command.should == "INDIRECTFRAME"
          @unnamed_frame = UnnamedIndirectFrame.new
          @unnamed_frame.command.should == "UNNAMEDINDIRECTFRAME"
        end

        it "should use a provided command name when it is provided" do
          @indirect_frame = IndirectFrame.new({}, nil, "MY_COMMAND")
          @indirect_frame.command.should == "MY_COMMAND"
          @named_frame = NamedIndirectFrame.new
          @named_frame.command.should == "TEST_COMMAND"
        end
      end
    end
  end
end
