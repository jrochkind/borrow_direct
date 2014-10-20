require 'test_helper'

require 'borrow_direct/find_item'



VCRFilter.sensitive_data! :bd_library_symbol, :bd_finditem
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_finditem

$REQUESTABLE_ITEM_ISBN     = "9810743734" # item is in BD, and can be requested
$LOCALLY_AVAIL_ITEM_ISBN   = "0745649890"  # item is in BD, but is avail locally so not BD-requestable
$NOT_REQUESTABLE_ITEM_ISBN = "1441190090" # in BD, and we don't have it, but no libraries let us borrow (in this case, it's an ebook)
$RETURNS_PUBFI002_ISBN     = "0109836413" # BD returns an error PUBFI002 for this one, which we want to treat as simply not available. 


describe "FindItem", :vcr => {:tag => :bd_finditem } do
  


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

    it "works with multiple values" do
      finder = BorrowDirect::FindItem.new("barcodeX", "libraryX")
      hash   = finder.send(:exact_search_request_hash, :isbn, ["2", "3"])

      exact_searches = hash["ExactSearch"]

      assert_length 2, exact_searches

      assert_include exact_searches, {"Type"=>"ISBN", "Value"=>"2"}
      assert_include exact_searches, {"Type"=>"ISBN", "Value"=>"3"}
    end
  end

  describe "#find_item_request" do

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
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => $REQUESTABLE_ITEM_ISBN)    
    end

    it "finds a locally available item" do
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => $LOCALLY_AVAIL_ITEM_ISBN)    
    end

    it "finds an item that does not exist in BD" do
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => "NO_SUCH_THING")
    end

    it "works with multiple values" do
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => [$REQUESTABLE_ITEM_ISBN, $LOCALLY_AVAIL_ITEM_ISBN])
    end

    describe "with expected error PUBFI002" do
      it "returns result" do
        assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => $RETURNS_PUBFI002_ISBN )
      end
    end
  end

  describe "find with Response" do
    before do
      @find_item = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol])
    end

    it "requestable for requestable item" do
      assert_equal true, @find_item.find(:isbn => $REQUESTABLE_ITEM_ISBN).requestable?
    end

    it "requestable with multiple items if at least one is requestable" do
      assert_equal true, @find_item.find(:isbn => [$REQUESTABLE_ITEM_ISBN, "NO_SUCH_ISBN"]).requestable?
    end

    it "not requestable for locally available item" do
      assert_equal false, @find_item.find(:isbn => $LOCALLY_AVAIL_ITEM_ISBN).requestable?
    end

    it "not requestable for item that does not exist in BD" do
      assert_equal false, @find_item.find(:isbn => "NO_SUCH_THING").requestable?
    end

    it "not requestable for item that no libraries will lend" do
      assert_equal false, @find_item.find(:isbn => $NOT_REQUESTABLE_ITEM_ISBN).requestable?
    end

    it "not requestable for item that BD returns PUBFI002" do
      assert_equal false, @find_item.find(:isbn => $RETURNS_PUBFI002_ISBN).requestable?
    end

    it "has an auth_id" do
      assert_present @find_item.find(:isbn => $REQUESTABLE_ITEM_ISBN).auth_id
    end

    it "has nil auth_id when BD doesn't want to give us one" do
      assert_nil @find_item.find(:isbn => $RETURNS_PUBFI002_ISBN).auth_id
    end

    it "has pickup locations" do
      pickup_locations = @find_item.find(:isbn => $REQUESTABLE_ITEM_ISBN).pickup_locations

      assert_present pickup_locations
      assert_kind_of Array, pickup_locations
    end

    it "has nil pickup locations when BD doesn't want to give us them" do
      assert_nil @find_item.find(:isbn => $RETURNS_PUBFI002_ISBN).pickup_locations
    end

  end



end