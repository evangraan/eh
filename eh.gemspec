# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eh/version'

Gem::Specification.new do |spec|
  spec.name          = "eh"
  spec.version       = ErrorHandler::VERSION
  spec.authors       = ["Ernst van Graan"]
  spec.email         = ["ernstvangraan@gmail.com"]
  spec.description   = %q{Error handler gem that allows wrapping of code blocks with support for block retry, logging, exception filtering and re-raise}
  spec.summary       = %q{Error handler gem that allows wrapping of code blocks with support for block retry, logging, exception filtering and re-raise}
  spec.homepage      = "https://github.com/evangraan/eh"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end
