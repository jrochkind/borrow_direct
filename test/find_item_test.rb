require 'test_helper'

require 'borrow_direct/find_item'



VCRFilter.sensitive_data! :bd_library_symbol, :bd_finditem
VCRFilter.sensitive_data! :bd_finditem_patron, :bd_finditem

REQUESTABLE_ITEM_ISBN     = "9810743734" # item is in BD, and can be requested
LOCALLY_AVAIL_ITEM_ISBN   = "0745649890"  # item is in BD, but is avail locally so not BD-requestable
NOT_REQUESTABLE_ITEM_ISBN = "1441190090" # in BD, and we don't have it, but no libraries let us borrow (in this case, it's an ebook)


describe "BorrowDirect::FindItem", :vcr => {:tag => :bd_finditem} do

  it "raises on no search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::FindItem.new("whatever", "whatever").find
    end
  end

  it "raises on multiple search critera" do
    assert_raises(ArgumentError) do
      BorrowDirect::FindItem.new("whatever", "whatever").find(:isbn => "1", :issn => "1")
    end
  end

  it "raises on unrecognized search criteria" do
    assert_raises(ArgumentError) do
      BorrowDirect::FindItem.new("whatever", "whatever").find(:whoknows => "1")
    end
  end


  it "finds a requestable item" do
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find(:isbn => REQUESTABLE_ITEM_ISBN)
  end

  it "finds a locally available item" do
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find(:isbn => LOCALLY_AVAIL_ITEM_ISBN)
  end

  it "finds an item that does not exist in BD" do
    resp = BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron] , VCRFilter[:bd_library_symbol]).find(:isbn => "NO_SUCH_THING")
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