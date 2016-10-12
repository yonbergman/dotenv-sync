# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dotenv/sync/version'

Gem::Specification.new do |spec|
  spec.name          = "dotenv-sync"
  spec.version       = Dotenv::Sync::VERSION
  spec.authors       = ["yonbergman"]
  spec.email         = ["yonbergman@gmail.com"]

  spec.summary       = %q{This gem let's you sync dotenv files through encrypted file}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["dotenv-sync"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "dotenv"
end
