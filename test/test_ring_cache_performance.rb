#!/usr/bin/env ruby

require File.expand_path('test_helper', File.dirname(__FILE__))
require 'minitest/benchmark'

class TestRingCachePerformance < Minitest::Benchmark
  include RandomDataGenerator

  def self.bench_range
    bench_exp(100, 100_000, 10)
  end

  def setup
    @data = random_data(1_000, 10)
  end

  # Computer-dependant -- but should be a reasonable baseline
  def bench_performance
    if ENV['BENCH']
      validation = lambda { |ranges, times|
        count_per_second = ranges.last / times.last.to_f
        assert count_per_second > 100_000, 'Count per second: %.2f' % count_per_second
      }

      assert_performance validation do |n|
        run_cache(n)
      end
    end
  end

  def bench_performance_linear
    if ENV['BENCH']
      assert_performance_linear do |n|
        run_cache(n)
      end
    end
  end

  private

  def run_cache(times, capacity = 1_000)
    cache = RingCache.new(capacity: capacity)
    count = 0
    while count < times
      element = @data.sample
      cache.fetch(element[:key]) do
        element[:content]
      end
      count += 1
    end
  end
end
