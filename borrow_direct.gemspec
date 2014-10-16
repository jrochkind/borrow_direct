# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'borrow_direct/version'

Gem::Specification.new do |spec|
  spec.name          = "borrow_direct"
  spec.version       = BorrowDirect::VERSION
  spec.authors       = ["Jonathan Rochkind"]
  spec.email         = ["jonathan@dnil.net"]
  spec.summary       = %q{Ruby tools for interacting with the Borrow Direct consortial services}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "httpclient", "~> 2.4"

  #spec.add_development_dependency "bundler", ">= 1.6.2", "< 2"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-vcr", ">= 1.0.2", "< 2"
  spec.add_development_dependency "vcr", "~> 2.9"
  spec.add_development_dependency "webmock", "~> 1.11"

end
