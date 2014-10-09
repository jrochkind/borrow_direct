require 'test_helper'
require 'borrow_direct/request'

SUCCESSFUL_ITEM_ISBN = "9810743734"


describe "BorrowDirect::Request", :vcr do


  it "raises on bad path"  do
    assert_raises(BorrowDirect::HttpError) do
      response = BorrowDirect::Request.new("/no/such/path").request( "foo" => "bar" )
    end
  end

  it "raises on bad request hash" do
    assert_raises(BorrowDirect::HttpError) do
      response = BorrowDirect::Request.new("/dws/item/available").request( "foo" => "bar" )
    end
  end

  it "gets BD error info" do
    request = {
        "PartnershipId" => "BAD_ID",
        "Credentials" => {
            "LibrarySymbol" => "librarySymbol",
            "Barcode" => "barcode/patronId"
        },
        "ExactSearch" => [
            {
                "Type" => "type",
                "Value" => "value"
            }
        ]
    }

    e = assert_raises(BorrowDirect::Error) do
      response = BorrowDirect::Request.new("/dws/item/available").request( request )      
    end

    refute_nil e
    refute_nil e.message
    refute_nil e.bd_code
  end

  it "can make a succesful request" do
      request = {
          "PartnershipId" => "BD",
          "Credentials" => {
              "LibrarySymbol" => "JOHNSHOPKINS",
              "Barcode" => "21151006865006"
          },
          "ExactSearch" => [
              {
                  "Type" => "ISBN",
                  "Value" => SUCCESSFUL_ITEM_ISBN
              }
          ]
      }

      
    response = BorrowDirect::Request.new("/dws/item/available").request( request )      
  end



end