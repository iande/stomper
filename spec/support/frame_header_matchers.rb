# -*- encoding: utf-8 -*-
RSpec::Matchers.define :have_header do |header_name, expected|
  match do |actual|
    actual[header_name.to_sym] == expected
  end
end

RSpec::Matchers.define :have_transaction_header do |expected|
  have_frame_header :transaction, expected
end
