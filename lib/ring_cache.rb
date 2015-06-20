require_relative 'ring_cache/key_not_found_error'
require_relative 'ring_cache/version'
require 'set'

class RingCache
  attr_reader :capacity, :target_hit_rate

  def initialize(options = {})
    @duplicate_on_store = options.fetch(:duplicate_on_store, false)
    @duplicate_on_retrieve = options.fetch(:duplicate_on_retrieve, false)

    execute_on_retrieve = options.fetch(:execute_on_retrieve, [])
    @execute_on_retrieve = execute_on_retrieve.kind_of?(Array) ? execute_on_retrieve : [execute_on_retrieve]

    @capacity = options.fetch(:capacity, nil)
    @target_hit_rate = options.fetch(:target_hit_rate, nil)
    unless @target_hit_rate.nil? or (@target_hit_rate > 0.0 and @target_hit_rate < 1.0)
      raise ArgumentError, 'Invalid target_hit_rate'
    end

    reset
  end

  def evict(key)
    if @cache.has_key?(key)
      @access_time_index.delete([@cache[key][:last_accessed_at], key])
      @cache.delete(key)
      true
    else
      false
    end
  end

  def fetch(key, &block)
    unless (data = read(key))
      data = catch(:dont_cache) do
        data_to_cache = block.call
        write(key, data_to_cache)
        data_to_cache
      end
    end
    data
  end

  def has_key?(key)
    @cache.has_key?(key)
  end

  def hit_rate
    (@access_count > 0) ? (@hit_count / @access_count.to_f) : 0.0
  end

  def last_access(key)
    has_key?(key) ? @cache[key][:last_accessed_at] : nil
  end

  def read!(key)
    @access_count += 1

    if @cache.has_key?(key)
      access_time = Time.now
      @access_time_index.delete([@cache[key][:last_accessed_at], key])
      @access_time_index << [access_time, key]
      @cache[key][:last_accessed_at] = access_time

      @hit_count += 1

      data = @cache[key][:data]
      data = data.dup if @duplicate_on_retrieve and !data.nil?

      unless @execute_on_retrieve.empty? or data.nil?
        @execute_on_retrieve.each do |method|
          method = method.to_sym
          if data.respond_to?(method)
            data.send(method)
          elsif data.kind_of?(Enumerable) and data.all? { |d| d.respond_to?(method) }
            data.each { |d| d.send(method) }
          else
            raise RuntimeError, "Retrieved data does not respond to #{method.inspect}"
          end
        end
      end

      data
    else
      fail KeyNotFoundError, "Cache does not have content indexed by #{key}"
    end
  end

  def read(key)
    read!(key)
  rescue KeyNotFoundError
    return nil
  end

  def reset
    @cache = {}
    @access_time_index = SortedSet.new
    @access_count = 0
    @hit_count = 0
    true
  end

  def size
    @cache.size
  end

  def write(key, data)
    unless evict(key)
      evict_oldest if must_evict?
    end
    data = data.dup if @duplicate_on_store and !data.nil?
    access_time = Time.now
    @cache[key] = { last_accessed_at: access_time, data: data }
    @access_time_index << [access_time, key]
    true
  end

  private

  def evict_oldest
    access_time_index_entry = @access_time_index.first
    @cache.delete(access_time_index_entry[1])
    @access_time_index.delete(access_time_index_entry)
  end

  def must_evict?
    (capacity and size >= capacity) or (target_hit_rate and hit_rate >= target_hit_rate)
  end
end
