# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  describe Headers do
    before(:each) do
      @headers = Headers.new
    end
    after(:each) do
      @headers.names.should == @headers.names.uniq
    end
    
    it "should allow setting and getting headers through a hash-style" do
      @headers[:header_1] = 'some value'
      @headers[:header_1].should == 'some value'
    end
    
    it "should translate keys to symbols" do
      @headers['other header'] = '42'
      @headers[:'other header'].should == '42'
      @headers['other header'].should == '42'
    end
    
    it "should translate header values to strings" do
      @headers['test header'] = 42
      @headers['test header'].should == '42'
      @headers['test header'] = nil
      @headers['test header'].should == ''
    end
    
    it "should return an array of header key/value pairs" do
      @headers['header 1'] = 'testing'
      @headers['other header'] = 19
      @headers[:tom] = 'servo'
      @headers.to_a.should == [ ['header 1', 'testing'], ['other header', '19'], ['tom', 'servo'] ]
    end
    
    it "should preserve the order of keys" do
      expected_keys = []
      20.times do |n|
        expected_keys << :"header #{n}"
        @headers["header #{n}"] = 'value'
      end
      @headers.names.should == expected_keys
    end
    
    it "should preserve the order of keys after deletion and insertion" do
      expected_keys = []
      20.times do |n|
        expected_keys << :"header #{n}" unless n == 3 || n == 16
        @headers["header #{n}"] = 'value'
      end
      expected_keys << :'header x'
      @headers.delete('header 3')
      @headers.delete('header 16')
      @headers['header x'] = 'value'
      @headers.names.should == expected_keys
    end
    
    it "should not duplicate existing keys" do
      expected_keys = []
      10.times do |n|
        expected_keys << :"header #{n}"
        @headers["header #{n}"] = 'value'
        @headers["header #{n}"] = 'other value'
        @headers.append("header #{n}", 'last value')
      end
      @headers.names.should == expected_keys
    end
    
    it "should maintain case sensitivity of keys" do
      @headers['headeR'] = 'value 1'
      @headers['Header'] = 'value 2'
      @headers[:header]  = 'value 3'
      @headers['headeR'].should == 'value 1'
      @headers['Header'].should == 'value 2'
      @headers['header'].should == 'value 3'
    end
    
    it "should overwrite header values through the hash-like interface" do
      @headers['header 1'] = 'first value'
      @headers[:'header 1'] = 'second value'
      @headers['header 1'] = 'third value'
      @headers[:'header 1'].should == 'third value'
    end
    
    it "should allow appending headers through the append interface method" do
      @headers.append('header 1', 'first value')
      @headers.append(:'header 1', 'second value')
      @headers.append('header 1', 'third value')
      @headers.all_values('header 1').should == ['first value', 'second value', 'third value']
    end
    
    it "should be convertable to an array" do
      @headers['header 1'] = 'first value'
      @headers['header 2'] = 'second value'
      @headers['header 3'] = 'third value'
      @headers.to_a.should == [['header 1', 'first value'], ['header 2', 'second value'], ['header 3', 'third value']]
    end
    
    it "should include duplicate headers in the array conversion" do
      @headers.append('header 1', 'h1 value 1')
      @headers.append('header 1', 'h1 value 2')
      @headers.append('header 1', 'h1 value 3')
      @headers['header 2'] = 'h2 value 1'
      @headers['header 3'] = 'h3 value 1'
      @headers.append('header 3', 'h3 value 2')
      @headers.to_a.should == [ ['header 1', 'h1 value 1'], ['header 1', 'h1 value 2'],
        ['header 1', 'h1 value 3'], ['header 2', 'h2 value 1'], ['header 3', 'h3 value 1'],
        ['header 3', 'h3 value 2'] ]
    end
    
    it "should set a header value to the first encountered in a chain of appends" do
      @headers.append('header 1', 'first value')
      @headers.append('header 1', 'second value')
      @headers.append('header 1', 'third value')
      @headers['header 1'].should == 'first value'
    end
    
    it "should be able to verify if a header has been set" do
      @headers['header 1'] = 'testing'
      @headers.has?(:'header 1').should be_true
      @headers.key?('header 1').should be_true
      @headers.include?('header 1').should be_true
      @headers.delete(:'header 1')
      @headers.has?(:'header 1').should_not be_true
      @headers.key?('header 1').should_not be_true
      @headers.include?('header 1').should_not be_true
    end
    
    describe "merging" do
      before(:each) do
        @headers = Headers.new({ :name1 => 'value 1', :name2 => 42, :name3 => false })
      end
      
      it "should have header names and values from the hash it was initialized from" do
        @headers.names.sort.should == [ :name1, :name2, :name3 ]
        @headers[:name1].should == 'value 1'
        @headers[:name2].should == '42'
        @headers[:name3].should == 'false'
      end
      
      it "should include keys and values from a merge, overwriting existing values" do
        @headers.merge!({ 'name2' => 'frankenberry', :name1 => 'faust', :name4 => 186 })
        @headers[:name1].should == 'faust'
        @headers[:name2].should == 'frankenberry'
        @headers[:name3].should == 'false'
        @headers[:name4].should == '186'
      end
      
      it "should include keys and values from a reverse merge, only if it did not have those names" do
        @headers.reverse_merge!(:name1 => 'chicken', :name5 => true, 'name2' => 1066)
        @headers[:name1].should == 'value 1'
        @headers[:name2].should == '42'
        @headers[:name3].should == 'false'
        @headers[:name5].should == 'true'
      end
    end
    
    describe "enumerability" do
      before(:each) do
        @headers['header 1'] = 'value 1'
        @headers.append('header 2', 'value 2')
        @headers.append('header 2', 'value 3')
        @expected_names = ['header 1', 'header 2', 'header 2']
        @expected_values = ['value 1', 'value 2', 'value 3']
        @received_names = []
        @received_values = []
        @iteration_result = nil
      end
      
      def iterate_with_arity_one(meth, collection=@headers)
        @received_names.clear
        @received_values.clear
        @iteration_result = collection.__send__(meth) do |kvp|
          @received_names << kvp.first
          @received_values << kvp.last
        end
      end
      
      def iterate_with_arity_two(meth, collection=@headers)
        @received_names.clear
        @received_values.clear
        @iteration_result = collection.__send__(meth) do |k,v|
          @received_names << k
          @received_values << v
        end
      end
      
      it "should be an Enumerable" do
        @headers.should be_a_kind_of(::Enumerable)
      end

      it "should iterate with :each, yielding appropriately depending on the arity of the block" do
        iterate_with_arity_one(:each)
        @received_names.should == @expected_names
        @received_values.should == @expected_values
        @iteration_result.should equal(@headers)
        
        iterate_with_arity_two(:each)
        @received_names.should == @expected_names
        @received_values.should == @expected_values
        @iteration_result.should equal(@headers)
      end
      
      if RUBY_VERSION >= '1.9'
        it "should yield an Enumerator if :each is called without a block" do
          enum = @headers.each
          enum.should be_a_kind_of(::Enumerator)
        
          iterate_with_arity_one(:each, enum)
          @received_names.should == @expected_names
          @received_values.should == @expected_values

          iterate_with_arity_two(:each, enum)
          @received_names.should == @expected_names
          @received_values.should == @expected_values
        end
      end
    end
  end
end
