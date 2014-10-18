lib = File.expand_path('../lib', File.dirname(__FILE__))
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)

require 'ring_cache'
require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
require File.expand_path('random_data_generator', File.dirname(__FILE__))

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
