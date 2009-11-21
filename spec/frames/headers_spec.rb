require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

module Stomper::Frames
  describe Headers do
    before(:each) do
      @headers = Headers.new
    end

    it "should set a header by a string key, accessible by all" do
      @test_value = "a test"
      @headers['testing'] = @test_value
      @headers['testing'].should == @test_value
      @headers[:testing].should == @test_value
      @headers.testing.should == @test_value
      @headers.send(:testing).should == @test_value
    end

    it "should set a header by a symbol key, accessible by all" do
      @test_value = "another test"
      @headers[:some_key] = @test_value
      @headers['some_key'].should == @test_value
      @headers[:some_key].should == @test_value
      @headers.some_key.should == @test_value
      @headers.send(:some_key).should == @test_value
    end

    it "should set a header by a method, accessible by all" do
      @test_value = "yet more testing"
      @headers.another_key = @test_value
      @headers['another_key'].should == @test_value
      @headers[:another_key].should == @test_value
      @headers.another_key.should == @test_value
      @headers.send(:another_key).should == @test_value
    end

    it "should override the default id getter and provide a setter" do
      @test_value = "my id"
      @headers.id = @test_value
      @headers.id.should == @test_value
      @headers['id'].should == @test_value
      @headers[:id].should == @test_value
      @headers.send(:id).should == @test_value
    end

    it "should provide method to convert to stomp compatible headers" do
      @headers.to_stomp.should be_empty
      @headers.ack = 'auto'
      @headers.destination = '/queue/test/1'
      @headers.to_stomp.should == "ack:auto\ndestination:/queue/test/1\n"
    end


  end
end