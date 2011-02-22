# -*- encoding: utf-8 -*-
Stomper::RUBY_SUPPORT = RUBY_VERSION >= '1.9' ? '1.9' : '1.8'

require "stomper/support/#{Stomper::RUBY_SUPPORT}/frame_serializer"
require "stomper/support/#{Stomper::RUBY_SUPPORT}/headers"
