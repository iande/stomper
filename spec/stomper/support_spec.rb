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
  end
end
