require_relative '../lib/ring_cache'
require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
require File.expand_path('random_data_generator', File.dirname(__FILE__))

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
