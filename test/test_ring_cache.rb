#!/usr/bin/env ruby

require File.expand_path('test_helper', File.dirname(__FILE__))

class TestRingCache < Minitest::Test
  include RandomDataGenerator

  def test_generic_checks
    c = RingCache.new(capacity: 3)
    c.write(:a, 1)
    assert_equal 0.0, c.hit_rate
    assert_equal 1, c.read(:a)
    assert_equal 1.0, c.hit_rate
    assert c.has_key?(:a)
    assert_kind_of Time, c.last_access(:a)
    assert_equal 1, c.size
    assert_equal 1, c.instance_variable_get(:@access_time_index).size

    c.write(:b, 2)
    assert_equal 2, c.read(:b)
    assert_equal 1.0, c.hit_rate
    assert c.has_key?(:b)
    assert_kind_of Time, c.last_access(:b)
    assert_equal 2, c.size
    assert_equal 2, c.instance_variable_get(:@access_time_index).size

    c.write(:c, 3)
    assert_equal 3, c.read(:c)
    assert_equal 1.0, c.hit_rate
    assert c.has_key?(:c)
    assert_kind_of Time, c.last_access(:c)
    assert_equal 3, c.size
    assert_equal 3, c.instance_variable_get(:@access_time_index).size

    c.write(:d, 4)
    assert_equal 4, c.read(:d)
    assert_equal 1.0, c.hit_rate
    assert c.has_key?(:d)
    assert_kind_of Time, c.last_access(:d)
    assert_equal 3, c.size
    assert_equal 3, c.instance_variable_get(:@access_time_index).size
    refute c.has_key?(:a)

    value = c.fetch(:b) do
      4
    end
    assert_equal 2, value
    assert_equal 1.0, c.hit_rate

    value = c.fetch(:e) do
      5
    end
    assert_equal 5, value
    assert_equal 3, c.size
    assert_equal 3, c.instance_variable_get(:@access_time_index).size
    refute c.has_key?(:c)
    assert_equal 5 / 6.0, c.hit_rate

    assert c.last_access(:b) > c.last_access(:d)
    assert c.last_access(:d) < c.last_access(:e)

    c.evict(:d)
    refute c.has_key?(:d)
    assert_equal 2, c.size
    assert_equal 2, c.instance_variable_get(:@access_time_index).size

    value = c.read(:another)
    assert_equal 5 / 7.0, c.hit_rate

    c.reset
    assert_equal 0, c.size
    assert_equal 0.0, c.hit_rate
  end

  def test_execute_method_on_retrieve
    test_class = Class.new
    test_class.class_eval do
      attr_reader :reloaded
      define_method(:inititalize) { @reloaded = false }
      define_method(:reload) { @reloaded = true }
    end

    cache = RingCache.new(execute_on_retrieve: :reload)

    data = test_class.new
    refute data.reloaded
    cache.write(:d1, data)
    retrieved_data = cache.read(:d1)
    assert retrieved_data.reloaded, retrieved_data.reloaded.inspect

    data = [
      test_class.new,
      test_class.new,
      test_class.new
    ]
    refute data.any? { |d| d.reloaded }
    cache.write(:d2, data)
    retrieved_data = cache.read(:d2)
    assert retrieved_data.all? { |e| e.reloaded }, retrieved_data.inspect

    data = Object.new
    refute_respond_to data, :reloaded
    cache.write(:d3, data)
    assert_raises RuntimeError do
      retrieved_data = cache.read(:d3)
    end
  end

  def test_object_duplication_on_retrieve
    c = RingCache.new(duplicate_on_retrieve: true)
    data = {a: 1, b: 2, c: 3}
    c.write(:d, data)
    assert c.has_key?(:d)
    retrieved_data = c.read(:d)
    assert data == retrieved_data
    refute data.equal?(retrieved_data)
  end

  def test_object_duplication_on_store
    c = RingCache.new(duplicate_on_store: true)
    data = {a: 1, b: 2, c: 3}
    c.write(:d, data)
    assert c.has_key?(:d)
    retrieved_data = c.read(:d)
    assert data == retrieved_data
    refute data.equal?(retrieved_data)
  end

  def test_random_data
    cache = RingCache.new(capacity: 1_000, target_hit_rate: 0.4)
    data = random_data(2_000, 10)

    10_000.times do
      element = data.sample
      cache.fetch(element[:key]) do
        element[:content]
      end
    end

    assert cache.size <= 1_000
    access_time_index = cache.instance_variable_get(:@access_time_index)
    cache_contents = cache.instance_variable_get(:@cache)
    assert_equal cache_contents.size, access_time_index.size

    access_time_index.each do |access_time_index_entry|
      assert cache_contents.has_key?(access_time_index_entry[1])
      assert_equal access_time_index_entry[0],
        cache_contents[access_time_index_entry[1]][:last_accessed_at]
    end
  end

  def test_target_hit_rate
    cache = RingCache.new(capacity: 4, target_hit_rate: 0.5)

    cache.fetch(:a) { 1 }
    cache.fetch(:b) { 2 }
    cache.read(:a)
    cache.read(:b)

    assert_equal 0.5, cache.hit_rate
    assert_equal 2, cache.size

    cache.read(:a)
    cache.read(:b)
    cache.fetch(:c) { 3 }

    assert_equal 4 / 7.0, cache.hit_rate
    assert_equal 2, cache.size
    assert cache.has_key?(:c)

    cache.fetch(:d) { 4 }
    assert_equal 4 / 8.0, cache.hit_rate
    assert_equal 2, cache.size
    assert cache.has_key?(:d)
  end

  def test_works_with_nil
    cache = RingCache.new(
      duplicate_on_store: true,
      duplicate_on_retrieve: true,
      execute_on_retrieve: :reload
    )
    data = nil
    cache.write(:d, data)
    assert_nil cache.read(:d)
  end
end
