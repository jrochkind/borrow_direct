require 'test_helper'
require 'json'
require 'httpclient'



VCRFilter.sensitive_data! :bd_library_symbol, :bd_auth
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_auth



describe "BD Authentication", :vcr => {:tag => :bd_auth} do
  describe "raw request to verify HTTP api" do
    it "works" do
      uri = BorrowDirect::Defaults.api_base.chomp("/") + "/portal-service/user/authentication/patron"


      request_hash = {
        "AuthenticationInformation" => {
          "LibrarySymbol" => VCRFilter[:bd_library_symbol],
          "PatronId" => VCRFilter[:bd_finditem_patron]
        }
      } 

      http = HTTPClient.new
      response = http.post uri, JSON.generate(request_hash), {"Content-Type" => "application/json", "User-Agent" => "ruby-borrow-direct-gem-#{BorrowDirect::VERSION}", "Accept-Language" => "en"}

      assert_equal 200, response.code
      assert_present response.body

      response_hash = JSON.parse response.body

      assert_present response_hash

      assert_present response_hash["Authentication"]["AuthnUserInfo"]["AId"]

    end
  end


end