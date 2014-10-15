require 'test_helper'
require 'json'
require 'httpclient'



VCRFilter.sensitive_data! :bd_library_symbol, :bd_auth
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_auth



describe "Authentication", :vcr => {:tag => :bd_auth} do
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
      response = http.post uri, JSON.generate(request_hash), {"Content-Type" => "application/json", "User-Agent" => "ruby borrow_direct gem (#{BorrowDirect::VERSION}) https://github.com/jrochkind/borrow_direct", "Accept-Language" => "en"}

      assert_equal 200, response.code
      assert_present response.body

      response_hash = JSON.parse response.body

      assert_present response_hash

      assert_present response_hash["Authentication"]["AuthnUserInfo"]["AId"]
    end
  end

  it "Makes a request succesfully" do
    bd = BorrowDirect::Authentication.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol])
    response = bd.authentication_request

    assert_present response
    assert_present response["Authentication"]["AuthnUserInfo"]["AId"]
  end

  it "Raises for bad library symbol" do
    bd = BorrowDirect::Authentication.new(VCRFilter[:bd_finditem_patron] , "BAD_SYMBOL")
    assert_raises(BorrowDirect::Error) do
      bd.authentication_request
    end
  end

  it "Raises for bad patron barcode" do
    bd = BorrowDirect::Authentication.new("BAD_BARCODE", VCRFilter[:bd_library_symbol])
    assert_raises(BorrowDirect::Error) do
      bd.authentication_request
    end
  end

  describe "get_auth_id" do
    it "returns an auth_id for a good request" do
      bd = BorrowDirect::Authentication.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol])
      assert_present bd.get_auth_id
    end

    it "raises for a bad library symbol" do
      bd = BorrowDirect::Authentication.new(VCRFilter[:bd_finditem_patron] , "BAD_SYMBOL")
      assert_raises(BorrowDirect::Error) do
        bd.get_auth_id
      end
    end

    it "raises for a bad patron barcode" do
      bd = BorrowDirect::Authentication.new("BAD_BARCODE", VCRFilter[:bd_library_symbol])
      assert_raises(BorrowDirect::Error) do
        bd.get_auth_id
      end
    end

  end



end