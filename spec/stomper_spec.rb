# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Stomper do
  it "should define a version" do
    Stomper.const_defined?(:VERSION).should be_true
    Stomper::VERSION.should == '1.1.0'
  end
end
