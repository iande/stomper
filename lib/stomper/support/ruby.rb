# -*- encoding: utf-8 -*-
::Stomper::Support::RUBY_SUPPORT = RUBY_VERSION >= '1.9' ? '1.9' : '1.8'

# Module for supporting Ruby 1.8.7
module Stomper::Support::Ruby1_8
end

# Module for supporting Ruby 1.9
module Stomper::Support::Ruby1_9
end

require "stomper/support/#{::Stomper::Support::RUBY_SUPPORT}/frame_serializer"
require "stomper/support/#{::Stomper::Support::RUBY_SUPPORT}/headers"
