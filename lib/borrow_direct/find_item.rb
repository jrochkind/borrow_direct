require 'borrow_direct'
require 'borrow_direct/request'

module BorrowDirect
  # The BorrowDirect FindItem service, for discovering item availability
  # http://borrowdirect.pbworks.com/w/file/83346676/Find%20Item%20Service.docx
  #
  #     BorrowDirect::FindItem.new(patron_barcode).bd_requestability?(:isbn => isbn)
  #     # or set BorrowDirect::Defaults.find_item_patron_barcode to make patron barcode
  #     # optional and use a default patron barcode
  #
  # You can also use #find_item_request to get the raw BD response as a ruby hash
  class FindItem < Request
    attr_reader :patron_barcode, :patron_library_symbol

    @@api_path = "/dws/item/available"
    @@valid_search_types = %w{ISBN ISSN LCCN OCLC PHRASE}


    def initialize(patron_barcode = Defaults.find_item_patron_barcode, 
                   patron_library_symbol = Defaults.library_symbol)
      super(@@api_path)

      @patron_barcode        = patron_barcode
      @patron_library_symbol = patron_library_symbol

      # BD sometimes unpredictably returns this error when it means
      # "no results", other times it doens't. We don't want to raise on it. 
      self.expected_error_codes << "PUBFI002"
    end

    # need to send a key and value for a valid exact_search type
    # type can be string or symbol, lowercase or uppercase. 
    #
    # Returns the actual complete BD response hash. You may want
    # #bd_requestable? instead
    #
    #    finder.find_item_request(:isbn => "12345545456")
    #
    # You can request multiple values which BD will treat as an 'OR'/union -- sort
    # of. BD does unpredictable things here, be careful. 
    #
    #     finder.find_item_request(:isbn => ["12345545456", "99999999"])
    def find_item_request(options)
      search_type, search_value = nil, nil
      options.each_pair do |key, value|
        if @@valid_search_types.include? key.to_s.upcase
          if search_type || search_value
            raise ArgumentError.new("Only one search criteria at a time is allowed: '#{options}'")
          end

          search_type, search_value = key, value
        end
      end
      unless search_type && search_value
        raise ArgumentError.new("Missing valid search type and value: '#{options}'")
      end

      request exact_search_request_hash(search_type, search_value)
    end

    # need to send a key and value for a valid exact_search type
    # type can be string or symbol, lowercase or uppercase. 
    #
    # Returns a BorrowDirect::FindItem::Response object, from which you
    # can find out requestability, list of pickup locations, etc. 
    def find(options)
      BorrowDirect::FindItem::Response.new find_item_request(options)
    end

    protected

    # Produce BD request hash for exact search of type eg "ISBN"
    # value can be a singel value, or an array of values. For array,
    # BD will "OR" them. 
    def exact_search_request_hash(type, value)
      # turn it into an array if it's not one already
      values = Array(value)

      hash = {
          "PartnershipId" => Defaults.partnership_id,
          "Credentials" => {
              "LibrarySymbol" => self.patron_library_symbol,
              "Barcode" => self.patron_barcode
          },
          "ExactSearch" => []
      }

      values.each do |value|
        hash["ExactSearch"] << {
            "Type" => type.to_s.upcase,
            "Value" => value
        }
      end
    
      return hash
    end

    class Response
      include BorrowDirect::Util

      attr_reader :response_hash
      
      def initialize(hash)
        @response_hash = hash
      end


      # Returns true or false -- can the item actually be requested
      # via BorrowDirect. 
      #
      #    finder.find(:isbn => "12345545456").requestable?
      def requestable?
        # Sometimes a PUBFI002 error code isn't really an error,
        # but just means not available. 
        if response_hash && response_hash["Error"] && (response_hash["Error"]["ErrorNumber"] == "PUBFI002")
          return false
        end

       # Items that are available locally, and thus not requestable via BD, can
       # only be found by looking at the RequestMessage, bah       
       if locally_available?
         return false
       end

       return response_hash["Item"]["Available"].to_s == "true"
      end

      # BD thinks the item is locally available at patron's home library,
      # and it is not requestable for that reason. 
      # Items that are available locally, and thus not requestable via BD, can
      # only be found by looking at the RequestMessage, bah       
      def locally_available?
       h = response_hash["Item"]["RequestLink"]
       return !! (h && h["RequestMessage"] == "This item is available locally")
      end

      # Returns the AuthorizationID returned by FindItem API call,
      # or nil if none is available. Nil _can_ be returned, for
      # instance when BD returns a NotFound error instead of a good
      # response. 
      def auth_id
        hash_key_path response_hash, "Item", "AuthorizationId"
      end

      # Can be nil in some cases if not requestable?
      # if requestable?, should be an array of Strings. 
      def pickup_locations
        hash_key_path response_hash, "Item", "PickupLocations", "PickupLocation"
      end


    end


  end
end