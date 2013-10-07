# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bones/rpc/version'

Gem::Specification.new do |spec|
  spec.name          = "bones-rpc-adapter-msgpack"
  spec.version       = Bones::RPC::Adapter::Msgpack::VERSION
  spec.authors       = ["Andrew Bennett"]
  spec.email         = ["andrew@pagodabox.com"]
  spec.description   = %q{Bones::RPC msgpack adapter for ruby}
  spec.summary       = %q{Bones::RPC msgpack adapter for ruby}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bones-rpc"

  if !!(RUBY_PLATFORM =~ /java/)
    spec.platform = 'java'
    spec.add_dependency "msgpack-jruby"
  else
    spec.platform = Gem::Platform::RUBY
    spec.add_dependency "msgpack"
  end

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
