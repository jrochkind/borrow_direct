require 'minitest'
require 'minitest/autorun'
require "minispec-metadata"


require 'vcr'
require 'webmock'
require 'minitest-vcr'

require 'borrow_direct'


# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb
end

MinitestVcr::Spec.configure!

# Silly way to not have to rewrite all our tests if we
# temporarily disable VCR, make VCR.use_cassette a no-op
# instead of no-such-method. 
if ! defined? VCR
  module VCR
    def self.use_cassette(*args)
      yield
    end
  end
end
