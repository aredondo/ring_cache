# RingCache

RingCache is an in-memory cache that emulates a ring buffer, in which older elements are evicted to make room for new ones. It is mostly useful in situations in which it is not worth it, or possible, to keep all accessed data in memory, and some elements are more frequently accessed than others.

As a ring buffer, it can work with a limited capacity. In addition, it allows the possibility of specifying a target hit rate, above which it will evict the elements that have not been accessed the longest. This should make it easier to optimize the amount of memory used when the hit rate becomes insensitive to the capacity over a given threshold—read [Pareto principle](https://en.wikipedia.org/wiki/Pareto_principle).

## Installation

RingCache does not have any dependency apart from Ruby Standard Library.

To install with Bundle, add the following line to the Gemfile:

    gem 'ring_cache'

And then execute:

    $ bundle

Otherwise, it can be installed with Rubygems as follows:

    $ gem install ring_cache

## Cache Initialization

RingCache accepts the following options to configure the size of the cache:

* `capacity`: The maximum number of elements that the cache will hold. By default, the capacity is unlimited.

* `target_hit_rate`: The cache will keep on growing in size until this target is achieved. Then, it will evict elements to make room for new ones to maintain its current size—as long as the hit rate is kept over this threshold. If the hit rate falls below the threshold, the cache will increase its size again. Size is always limited by the `capacity` option. By default, there is no target hit rate.

The following options allow some control over the stored data:

* `duplicate_on_store` : Store a duplicate of the element obtained with `dup` rather than the element provided to the cache.
* `duplicate_on_retrieve`: Return a duplicate of the accessed data rather than the accessed data itself.
* `execute_on_retrieve`: Method or array of methods that should be executed on accessed data before returning it. This could be used, for example, to ensure that returned data is fresh.

Initialization example:

```ruby
cache = RingCache.new(
  capacity: 2_000,
  target_hit_rate: 0.9,
  execute_on_retrieve: :reload
)
```

## Usage

To access data, use the `read` and `write` methods:

```ruby
cache.write(:example, 'Lorem ipsum')
test = cache.read(:example)
# => "Lorem ipsum"
```

Both keys and values can be any data type.

The `read` method returns `nil` by default when the cache does not contain the requested key. Alternatively, `read!` raises a `RingCache::KeyNotFoundError` exception when the requested element is not in the cache.

Use `fetch` as a shortcut to provide missing, more-costly-to-load data in a block:

```ruby
cache.fetch(:example) do
  'Lorem ipsum'
end
# => "Lorem ipsum"
```

By default, `fetch` will cache anything returned from the block. The option `cache_nil` allows specifying whether `nil` values should also be cache, and defaults to `true`:

```ruby
cache.fetch(:example, cache_nil: false) do
  nil
end
# => nil

cache.has_key?(:example)
# => false
```

If already within the block it is determined that the returned content should not be cached, it is possible to throw a `:dont_cache` symbol. Optionally, the symbol can be accompanied by the value that should be returned from the block—while not cached:

```ruby
cache.fetch(:example) do
  throw :dont_cache, true
end
# => true

cache.has_key?(:example)
# => false
```

Use `evict` to remove an element from the cache:

```ruby
cache.evict(:example)
# => true
```

And `reset` to completely erase the cache contents—while maintaining initialization options.

There are other methods that just return information:

* `has_key?(key)`: Returns true if the cache contains an element indexed by this key. Otherwise, false.
* `hit_rate`: Current hit rate of the cache. This is a number between 0 and 1.
* `last_access(key)`: Time when the element indexed by this key was last accessed.
* `size`: Number of elements currently stored in the cache.

## Contributing

Please, fork the repository, make your changes, and submit a pull request. Thanks!
