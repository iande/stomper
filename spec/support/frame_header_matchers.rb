# -*- encoding: utf-8 -*-
RSpec::Matchers.define :have_header do |header_name, expected|
  match do |actual|
    actual[header_name.to_sym] == expected
  end
end

RSpec::Matchers.define :have_transaction_header do |expected|
  have_frame_header :transaction, expected
end

RSpec::Matchers.define :have_command do |expected|
  match do |actual|
    actual.command.should == expected
  end
end

RSpec::Matchers.define :have_body_encoding do |expected|
  if RUBY_VERSION >= "1.9"
    match do |actual|
      actual.body.encoding.name.should == expected
    end
  else
    match do |actual|
      true.should be_true
    end
  end
end

RSpec::Matchers.define :have_body do |expected, expected_no_encoding, encoding|
  e_expected = (RUBY_VERSION >= '1.9') ? expected.encode(encoding) : expected_no_encoding
  match do |actual|
    actual.body.should == e_expected
  end
end
