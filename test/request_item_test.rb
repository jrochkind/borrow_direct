require 'test_helper'
require 'vcr'

require 'borrow_direct/authentication'
require 'borrow_direct/request_item'





describe "RequestItem", :vcr => {:tag => :bd_requestitem } do 
  before do
    @requestable_item_isbn     = "9797994864" # item is in BD, and can be requested
    @locally_avail_item_isbn   = "0745649890"  # item is in BD, but is avail locally so not BD-requestable
    @not_requestable_item_isbn = "1441190090" # in BD, and we don't have it, but no libraries let us borrow (in this case, it's an ebook)
    @returns_PUBRI004_ISBN     = "0109836413" # BD returns an error PUBRI004 for this one, which we want to treat as simply not available. 
    @pickup_location           = "Some location" # BD seems to allow anything, which is disturbing
  end

  it "raw RequestItem sanity check", :vcr => {:record => :all} do
    findable = BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).find(:isbn => @requestable_item_isbn)

    assert findable.requestable?

    pickup = findable.pickup_locations.first
    aid    = findable.auth_id

    uri = BorrowDirect::Defaults.api_base.chomp("/") + "/dws/item/add?aid=#{CGI.escape aid}"

    request_hash = {
      "PartnershipId" => BorrowDirect::Defaults.partnership_id,
      "PickupLocation" => pickup,
      "ExactSearch" => [
        {"Type":"ISBN","Value": @requestable_item_isbn}
      ]
    } 

    http = HTTPClient.new
    response = http.post uri, JSON.generate(request_hash), {"Content-Type" => "application/json", "User-Agent" => "ruby borrow_direct gem (#{BorrowDirect::VERSION}) https://github.com/jrochkind/borrow_direct", "Accept-Language" => "en"}

    assert_equal 200, response.code
    assert_present response.body

    response_hash = JSON.parse response.body

    assert_present response_hash
  end



  it "raises on no search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::RequestItem.new("whatever").request_item_request
    end
  end

  it "raises on multiple search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::RequestItem.new("whatever").request_item_request(nil, :isbn => "1", :issn => "1")
    end
  end

  it "raises on unrecognized search criteria" do
    assert_raises(ArgumentError) do
      BorrowDirect::RequestItem.new("whatever").request_item_request(nil, :whoknows => "1")
    end
  end


  it "raw requests an unrequestable item" do    

    resp = BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).request_item_request(nil, :isbn => @not_requestable_item_isbn)

    assert_present resp
    assert_present resp["Request"]
  end

  it "uses manually set auth_id" do
    bd          = BorrowDirect::RequestItem.new("bad_patron" , "bad_symbol")
    bd.auth_id  = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).get_auth_id  
    resp        = bd.request_item_request(nil, :isbn => @requestable_item_isbn)

    assert_present resp
    assert_present resp["Request"]
  end

  describe "make_request" do
    it "make_request for a requestable item" do
      request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => @requestable_item_isbn)

      assert_present request_id    
    end

    it "make_request for an unrequestable item" do
      resp = BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => @not_requestable_item_isbn)

      assert_nil resp
    end

    it "make_request for a locally available item" do
      resp = BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => @locally_avail_item_isbn)

      assert_nil resp
    end

    it "says no for item that BD returns PUBRI004" do
      assert_nil BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => @returns_PUBRI004_ISBN)
    end

  end

  describe "with pickup location and requestable item", :vcr => {:record => :all} do
    it "still works" do
      request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).make_request(@pickup_location, :isbn => @requestable_item_isbn)

      assert_present request_id    
    end
  end

  describe "make_request!" do
    it "returns number for succesful request" do
      request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).make_request!(nil, :isbn => @requestable_item_isbn)

      assert_present request_id    
    end

    it "raises for unrequestable" do
      error = assert_raises(BorrowDirect::Error) do
        request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).make_request!(nil, :isbn => @not_requestable_item_isbn)
      end
    end
    
  end




end