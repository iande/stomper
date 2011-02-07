# -*- encoding: utf-8 -*-
# Spec::Matchers.define :be_a_registered_server_frame do
#   match do |actual|
#     command_name = actual.name.split('::').last.upcase
#     frame = Stomp::Frames::ServerFrame.build(command_name, { :a_header => 'test' }, 'body')
#     frame.should be_an_instance_of(actual)
#     frame.command.should == command_name
#     frame.headers[:a_header].should == 'test'
#     frame.body.should == 'test body'
#   end
# end
# 
# Spec::Matchers.define :be_able_to_access_header_values_like_a_hash do
#   match do |actual|
#     frame = actual.new( { :header_1 => 1, :header_2 => 'test' })
#     frame[:header_1].should == 1
#     frame[:header_2].should == 'test'
#   end
# end
