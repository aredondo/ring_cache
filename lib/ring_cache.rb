require 'ring_cache/version'
require 'set'

class RingCache
  attr_reader :capacity

  def initialize(options = {})
    @duplicate_on_store = options.fetch(:duplicate_on_store, false)
    @duplicate_on_retrieve = options.fetch(:duplicate_on_retrieve, false)
    execute_on_retrieve = options.fetch(:execute_on_retrieve, [])
    @execute_on_retrieve = execute_on_retrieve.kind_of?(Array) ? execute_on_retrieve : [execute_on_retrieve]
    @capacity = options.fetch(:capacity, 25)
    reset
  end

  def evict(key)
    return false unless @cache.has_key?(key)
    @access_time_index.delete([@cache[key][:last_accessed_at], key])
    @cache.delete(key)
  end

  def fetch(key, &block)
    unless (data = read(key))
      data = block.call
      write(key, data)
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

  def read(key)
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
      nil
    end
  end

  def reset
    @cache = {}
    @access_time_index = SortedSet.new
    @access_count = 0
    @hit_count = 0
  end

  def size
    @cache.size
  end

  def write(key, data)
    maintain_cache_size(true)
    data = data.dup if @duplicate_on_store and !data.nil?
    access_time = Time.now
    @cache[key] = { last_accessed_at: access_time, data: data }
    @access_time_index << [access_time, key]
  end

  private

  def maintain_cache_size(make_room_for_new_element = false)
    target_size = make_room_for_new_element ? (capacity - 1) : capacity
    deleted_count = 0

    while @cache.size > target_size
      access_time_index_entry = @access_time_index.first
      @cache.delete(access_time_index_entry[1])
      @access_time_index.delete(access_time_index_entry)
      deleted_count += 1
    end

    deleted_count
  end
end
