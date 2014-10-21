require 'test_helper'
require 'json'
require 'httpclient'


describe "top level describe", :vcr do

  describe "an inner describe" do
    it "a test inside inner describe" do
      HTTPClient.new.get "http://example.org"
    end
  end

  it "makes a request succesfully" do
  end
end