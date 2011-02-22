# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe Support do
    before(:each) do
      @hash = {
        'a' => 'value 1',
        :somekey => ['a', :set, 'of values', 33],
        '13' => nil
      }
    end
    
    describe "keys_to_sym" do
      it "should symbolize the keys of a hash without changing the original hash" do
        symbolized_hash = Support.keys_to_sym(@hash)

        @hash['a'].should == 'value 1'
        @hash[:somekey].should == ['a', :set, 'of values', 33]
        @hash['13'].should be_nil
                
        symbolized_hash.keys.sort.should == [ :'13', :a, :somekey ]
        symbolized_hash[:a].should == 'value 1'
        symbolized_hash[:somekey].should == ['a', :set, 'of values', 33]
        symbolized_hash[:'13'].should be_nil
      end
    end
    
    describe "keys_to_sym!" do
      it "should symbolize the keys of a hash and replace the existing hash" do
        Support.keys_to_sym!(@hash)
        @hash.keys.sort.should == [ :'13', :a, :somekey ]
        @hash[:a].should == 'value 1'
        @hash[:somekey].should == ['a', :set, 'of values', 33]
        @hash[:'13'].should be_nil
      end
    end
    
    describe "next_serial" do
      it "should generate sequential numbers" do
        first = Support.next_serial.to_i
        second = Support.next_serial.to_i
        third = Support.next_serial.to_i
        first.should == second - 1
        second.should == third - 1
      end
    end
    
    describe "constantize" do
      it "should constantize a Class" do
        Support.constantize(Class).should == ::Class
        Support.constantize(::Stomper::Extensions::Events).should == ::Stomper::Extensions::Events
      end
      
      it "should constantize string representations of known classes" do
        Support.constantize("Module").should == ::Module
        Support.constantize("::Module").should == ::Module
        Support.constantize("::Stomper::Extensions").should == ::Stomper::Extensions
        Support.constantize("Stomper::Receivers::Threaded").should == ::Stomper::Receivers::Threaded
      end
      
      it "should fail to constantize un-resolvable classes" do
        lambda { Support.constantize("::Not::::Valid") }.should raise_error(NameError)
        lambda { Support.constantize("Module::Does::Not::Exist") }.should raise_error(NameError)
        lambda { Support.constantize("::Stomper::FrameSerializer::Nada") }.should raise_error(NameError)
      end
    end
  end
end
