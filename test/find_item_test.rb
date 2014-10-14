require 'test_helper'

require 'borrow_direct/find_item'



VCRFilter.sensitive_data! :bd_library_symbol, :bd_finditem
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_finditem

REQUESTABLE_ITEM_ISBN     = "9810743734" # item is in BD, and can be requested
LOCALLY_AVAIL_ITEM_ISBN   = "0745649890"  # item is in BD, but is avail locally so not BD-requestable
NOT_REQUESTABLE_ITEM_ISBN = "1441190090" # in BD, and we don't have it, but no libraries let us borrow (in this case, it's an ebook)


describe "BorrowDirect::FindItem", :vcr => {:tag => :bd_finditem, :match_requests_on => [:body]} do

  describe "with defaults" do
    before do
      @original_symbol = BorrowDirect::Defaults.library_symbol
      @original_bar    = BorrowDirect::Defaults.find_item_patron_barcode
      BorrowDirect::Defaults.library_symbol = "OUR_SYMBOL"      
      BorrowDirect::Defaults.find_item_patron_barcode = "OUR_BARCODE"      
    end
    after do 
      BorrowDirect::Defaults.library_symbol = @original_symbol    
      BorrowDirect::Defaults.find_item_patron_barcode = @original_bar
    end

    it "uses defaults" do
      finder = BorrowDirect::FindItem.new

      assert_equal "OUR_SYMBOL",  finder.patron_library_symbol
      assert_equal "OUR_BARCODE", finder.patron_barcode
    end
  end

  describe "query production" do
    it "exact search works" do
      finder = BorrowDirect::FindItem.new("barcodeX", "libraryX")
      hash   = finder.send(:exact_search_request_hash, :isbn, "2")

      assert_equal BorrowDirect::Defaults.partnership_id, hash["PartnershipId"]
      assert_equal "barcodeX", hash["Credentials"]["Barcode"]
      assert_equal "libraryX", hash["Credentials"]["LibrarySymbol"]

      assert_equal "ISBN", hash["ExactSearch"].first["Type"]
      assert_equal "2", hash["ExactSearch"].first["Value"]
    end
  end


  it "raises on no search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::FindItem.new("whatever", "whatever").find_item_request
    end
  end

  it "raises on multiple search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::FindItem.new("whatever", "whatever").find_item_request(:isbn => "1", :issn => "1")
    end
  end

  it "raises on unrecognized search criteria" do
    assert_raises(ArgumentError) do
      BorrowDirect::FindItem.new("whatever", "whatever").find_item_request(:whoknows => "1")
    end
  end


  it "finds a requestable item" do
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => REQUESTABLE_ITEM_ISBN)
  end

  it "finds a locally available item" do
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => LOCALLY_AVAIL_ITEM_ISBN)
  end

  it "finds an item that does not exist in BD" do
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => "NO_SUCH_THING")
  end

  #describe "bd_requestable?" do
    it "says yes for requestable item" do
      assert_equal true, BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).bd_requestable?(:isbn => REQUESTABLE_ITEM_ISBN)
    end

    it "says no for locally available item" do
      assert_equal false, BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).bd_requestable?(:isbn => LOCALLY_AVAIL_ITEM_ISBN)
    end

    it "says no for item that does not exist in BD" do
      assert_equal false, BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).bd_requestable?(:isbn => "NO_SUCH_THING")
    end

    it "says no for item that no libraries will lend" do
      assert_equal false, BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).bd_requestable?(:isbn => NOT_REQUESTABLE_ITEM_ISBN)
    end

  #end


end