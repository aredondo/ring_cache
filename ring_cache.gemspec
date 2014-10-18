# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ring_cache/version'

Gem::Specification.new do |spec|
  spec.name          = 'ring_cache'
  spec.version       = RingCache::VERSION
  spec.authors       = ['Alvaro Redondo']
  spec.email         = ['alvaro@redondo.name']
  spec.summary       = %q{In-memory cache that emulates a ring buffer.}
  spec.description   = %q{RingCache is an in-memory cache that emulates a ring buffer, in which older elements are evicted to make room for new ones.}
  spec.homepage      = 'https://github.com/aredondo/ring_cache'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
