#!/usr/bin/env ruby

require File.expand_path('test_helper', File.dirname(__FILE__))

class TestRingCacheIssues < Minitest::Test
  def test_records_one_index_per_entry
    c = RingCache.new

    c.write(:a, 1)
    c.write(:a, 2)

    assert_equal 1, c.size
    access_time_index = c.instance_variable_get(:@access_time_index)
    assert_equal 1, access_time_index.size
  end
end
