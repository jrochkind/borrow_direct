require 'test_helper'
require 'vcr'

require 'borrow_direct/find_item'
require 'borrow_direct/request_item'



VCRFilter.sensitive_data! :bd_library_symbol, :bd_requestitem
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_requestitem

REQUESTABLE_ITEM_ISBN     = "9797994864" # item is in BD, and can be requested
LOCALLY_AVAIL_ITEM_ISBN   = "0745649890"  # item is in BD, but is avail locally so not BD-requestable
NOT_REQUESTABLE_ITEM_ISBN = "1441190090" # in BD, and we don't have it, but no libraries let us borrow (in this case, it's an ebook)



describe "BorrowDirect::RequestItem", :vcr => {:tag => :bd_requestitem, :match_requests_on => [:method, :uri, :body]} do



  it "raises on no search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::RequestItem.new("whatever").request_item_request
    end
  end

  it "raises on multiple search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::RequestItem.new("whatever").request_item_request(:isbn => "1", :issn => "1")
    end
  end

  it "raises on unrecognized search criteria" do
    assert_raises(ArgumentError) do
      BorrowDirect::RequestItem.new("whatever").request_item_request(:whoknows => "1")
    end
  end


  it "raw requests an unrequestable item" do
    auth_id = make_find_item_for_auth(:isbn => NOT_REQUESTABLE_ITEM_ISBN)

    resp = BorrowDirect::RequestItem.new(auth_id).request_item_request(:isbn => NOT_REQUESTABLE_ITEM_ISBN)


    assert_present resp
    assert_present resp["Request"]
  end

  describe "make_request" do
    it "make_request for a requestable item" do
      auth_id = make_find_item_for_auth(:isbn => REQUESTABLE_ITEM_ISBN)

      request_id = BorrowDirect::RequestItem.new(auth_id).make_request(:isbn => REQUESTABLE_ITEM_ISBN)

      assert_present request_id    
    end

    it "make_request for an unrequestable item" do
      auth_id = make_find_item_for_auth(:isbn => NOT_REQUESTABLE_ITEM_ISBN)

      resp = BorrowDirect::RequestItem.new(auth_id).make_request(:isbn => NOT_REQUESTABLE_ITEM_ISBN)

      assert_nil resp
    end

    it "make_request for a locally available item" do
      auth_id = make_find_item_for_auth(:isbn => LOCALLY_AVAIL_ITEM_ISBN)

      resp = BorrowDirect::RequestItem.new(auth_id).make_request(:isbn => LOCALLY_AVAIL_ITEM_ISBN)

      assert_nil resp
    end
  end

  describe "make_request!" do
    it "returns number for succesful request" do
      auth_id = make_find_item_for_auth(:isbn => REQUESTABLE_ITEM_ISBN)

      request_id = BorrowDirect::RequestItem.new(auth_id).make_request!(:isbn => REQUESTABLE_ITEM_ISBN)

      assert_present request_id    
    end

    it "raises for unrequestable" do
      auth_id = make_find_item_for_auth(:isbn => NOT_REQUESTABLE_ITEM_ISBN)

      error = assert_raises(BorrowDirect::Error) do
        request_id = BorrowDirect::RequestItem.new(auth_id).make_request!(:isbn => NOT_REQUESTABLE_ITEM_ISBN)
      end
    end
    
  end


  # Helper method to do the FindItem and get a BD AuthorizationID, sadly
  # neccesary first for making a request, really slowing things down yes. 
  def make_find_item_for_auth(conditions)
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => REQUESTABLE_ITEM_ISBN)
    auth_id = resp["Item"]["AuthorizationId"]

    assert ! auth_id.nil?, "No AuthorizationId received from BD"

    return auth_id
  end

end