require 'test_helper'
require 'vcr'

require 'borrow_direct/authentication'
require 'borrow_direct/request_item'



VCRFilter.sensitive_data! :bd_library_symbol, :bd_requestitem
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_requestitem

$REQUESTABLE_ITEM_ISBN     = "9797994864" # item is in BD, and can be requested
$LOCALLY_AVAIL_ITEM_ISBN   = "0745649890"  # item is in BD, but is avail locally so not BD-requestable
$NOT_REQUESTABLE_ITEM_ISBN = "1441190090" # in BD, and we don't have it, but no libraries let us borrow (in this case, it's an ebook)
$RETURNS_PUBRI004_ISBN     = "0109836413" # BD returns an error PUBRI004 for this one, which we want to treat as simply not available. 
$PICKUP_LOCATION           = "Some location" # BD seems to allow anything, which is disturbing


describe "RequestItem", :vcr => {:tag => :bd_requestitem } do



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

    resp = BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).request_item_request(nil, :isbn => $NOT_REQUESTABLE_ITEM_ISBN)

    assert_present resp
    assert_present resp["Request"]
  end

  it "uses manually set auth_id" do
    bd          = BorrowDirect::RequestItem.new("bad_patron" , "bad_symbol")
    bd.auth_id  = BorrowDirect::Authentication.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).get_auth_id  
    resp        = bd.request_item_request(nil, :isbn => $REQUESTABLE_ITEM_ISBN)

    assert_present resp
    assert_present resp["Request"]
  end

  describe "make_request" do
    it "make_request for a requestable item" do
      request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => $REQUESTABLE_ITEM_ISBN)

      assert_present request_id    
    end

    it "make_request for an unrequestable item" do
      resp = BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => $NOT_REQUESTABLE_ITEM_ISBN)

      assert_nil resp
    end

    it "make_request for a locally available item" do
      resp = BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => $LOCALLY_AVAIL_ITEM_ISBN)

      assert_nil resp
    end

    it "says no for item that BD returns PUBRI004" do
      assert_nil BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).make_request(nil, :isbn => $RETURNS_PUBRI004_ISBN)
    end

  end

  describe "with pickup location and requestable item" do
    it "still works" do
      request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).make_request($PICKUP_LOCATION, :isbn => $REQUESTABLE_ITEM_ISBN)

      assert_present request_id    
    end
  end

  describe "make_request!" do
    it "returns number for succesful request" do
      request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).make_request!(nil, :isbn => $REQUESTABLE_ITEM_ISBN)

      assert_present request_id    
    end

    it "raises for unrequestable" do
      error = assert_raises(BorrowDirect::Error) do
        request_id = BorrowDirect::RequestItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).make_request!(nil, :isbn => $NOT_REQUESTABLE_ITEM_ISBN)
      end
    end
    
  end




end