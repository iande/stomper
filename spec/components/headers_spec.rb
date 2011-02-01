# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper
  module Components
    describe Headers do
      before(:each) do
        @headers = ::Stomper::Components::Headers.new
      end
      after(:each) do
        @headers.names.should == @headers.names.uniq
      end
      
      it "should allow setting and getting headers through a hash-style" do
        @headers[:header_1] = 'some value'
        @headers[:header_1].should == 'some value'
      end
      
      it "should translate keys to strings" do
        @headers['other header'] = '42'
        @headers[:'other header'].should == '42'
        @headers['other header'].should == '42'
      end
      
      it "should translate non-nil header values to strings" do
        @headers['test header'] = 42
        @headers['test header'].should == '42'
        @headers['test header'] = nil
        @headers['test header'].should be_nil
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
          expected_keys << "header #{n}"
          @headers["header #{n}"] = 'value'
        end
        @headers.names.should == expected_keys
      end
      
      it "should preserve the order of keys after deletion and insertion" do
        expected_keys = []
        20.times do |n|
          expected_keys << "header #{n}" unless n == 3 || n == 16
          @headers["header #{n}"] = 'value'
        end
        expected_keys << 'header x'
        @headers.delete('header 3')
        @headers.delete('header 16')
        @headers['header x'] = 'value'
        @headers.names.should == expected_keys
      end
      
      it "should not duplicate existing keys" do
        expected_keys = []
        10.times do |n|
          expected_keys << "header #{n}"
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
        @headers['header 1'] = 'second value'
        @headers['header 1'] = 'third value'
        @headers['header 1'].should == 'third value'
      end
      
      it "should allow appending headers through the append interface method" do
        @headers.append('header 1', 'first value')
        @headers.append('header 1', 'second value')
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
      
      it "should be an Enumerable" do
        @headers.should be_a_kind_of(::Enumerable)
      end
      
      it "should yield an Enumerator if :each is called without a block" do
        @headers.each.should be_a_kind_of(::Enumerator)
      end
    end
  end
end
