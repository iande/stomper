# -*- encoding: utf-8 -*-
require 'spec_helper'

module Stomper::Extensions
  describe Scoping do
    before(:each) do
      @scoping = mock("scoping", :version => '1.0')
      @scoping.extend Scoping
    end
    
    it "should return a new HeaderScope" do
      @scoping.with_headers({}).should be_an_instance_of(::Stomper::Scopes::HeaderScope)
    end
    it "should return a new TransactionScope" do
      @scoping.with_transaction.should be_an_instance_of(::Stomper::Scopes::TransactionScope)
    end
    it "should return a new ReceiptScope" do
      @scoping.with_receipt.should be_an_instance_of(::Stomper::Scopes::ReceiptScope)
    end
  end
end
