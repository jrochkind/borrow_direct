require 'test_helper'
require 'httpclient'


VCRFilter.sensitive_data! :bd_library_symbol, :bd_request_query
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_request_query

$REQUESTABLE_ITEM_ISBN     = "9797994864" # item is in BD, and can be requested

describe "RequestQuery", :vcr => {:tag => :bd_request_query} do
  it "raw request to verify the BD HTTP API" do

    # Get the auth code

    auth_uri = BorrowDirect::Defaults.api_base.chomp("/") + "/portal-service/user/authentication/patron"
    auth_hash = {
        "AuthenticationInformation" => {
          "LibrarySymbol" => VCRFilter[:bd_library_symbol],
          "PatronId" => VCRFilter[:bd_finditem_patron]
        }
      } 

    headers = { "Content-Type" => "application/json", 
        "User-Agent" => "ruby borrow_direct gem #{BorrowDirect::VERSION} (HTTPClient #{HTTPClient::VERSION}) https://github.com/jrochkind/borrow_direct", 
        "Accept-Language" => "en"
      }
    http = HTTPClient.new
    response = http.post auth_uri, JSON.generate(auth_hash), headers
    response_hash = JSON.parse response.body
    auth_id = response_hash["Authentication"]["AuthnUserInfo"]["AId"]

    
    # Now use it to make a RequestQuery request. Note, BD API requires
    # you to use the same User-Agent you used to receive the auth id. 


      query = {
        "aid" => auth_id,
        "type" => "open",
        "fullRecord" => "0"
      }

      uri = BorrowDirect::Defaults.api_base.chomp("/") + "/portal-service/request/query/my"            

      http = HTTPClient.new
      http_response = http.get uri, query, headers

      assert_equal 200, http_response.code
      assert_present http_response.body

      response_hash = JSON.parse http_response.body

      assert_present response_hash
      assert_present response_hash["QueryResult"]
      assert_kind_of Array, response_hash["QueryResult"]["MyRequestRecords"]
      
  end


  # Helper method to do the FindItem and get a BD AuthorizationID, sadly
  # neccesary first for making a request, really slowing things down yes. 
  def make_find_item_for_auth(conditions)
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => $REQUESTABLE_ITEM_ISBN)
    auth_id = resp["Item"]["AuthorizationId"]

    assert ! auth_id.nil?, "No AuthorizationId received from BD"

    return auth_id
  end

end



