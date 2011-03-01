# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Stomper do
  it "should define a version" do
    Stomper.const_defined?(:VERSION).should be_true
  end
end
