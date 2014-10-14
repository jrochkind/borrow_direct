require 'borrow_direct'
require 'borrow_direct/request'

module BorrowDirect
  # The BorrowDirect RequestItem service, for placing a request
  # http://borrowdirect.pbworks.com/w/file/86126056/RequestItem.docx
  #
  # You can also use #find_item_request to get the raw BD response as a ruby hash
  class RequestItem < Request
    attr_reader :authorization_id

    @@api_path = "/dws/item/add"
    @@valid_search_types = %w{ISBN ISSN LCCN OCLC Control }


    # Need an AuthorizationId acquired from a previous FindItem request, probably. 
    def initialize(auth_id)
      super(@@api_path)

      @authorization_id      = auth_id      
    end

    # need to send a key and value for a valid exact_search type
    # type can be string or symbol, lowercase or uppercase. 
    #
    # Returns the actual complete BD response hash. You may want
    # #make_request instead
    #
    #    finder.request_item_request(:isbn => "12345545456")
    #    finder.request_item_request(:lccn => "12345545456")
    #    finder.request_item_request(:oclc => "12345545456")
    def request_item_request(options)
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

    # Pass in a BD exact search eg
    #     make_request(:isbn => isbn)
    #
    # Returns the BD RequestNumber, or nil if a request could
    # not be made
    #
    # See also make_request! to raise if request can not be made
    def make_request(options)
      resp = request_item_request(options)

      return extract_request_number(resp)
    end

    # Like make_request, but will raise a BorrowDirect::Error if
    # item can't be requested. 
    def make_request!(options)
      resp = request_item_request(options)

      number = extract_request_number(resp)

      if number.nil?
        raise BorrowDirect::Error.new("Can not request for: #{options.inspect}: #{resp.inspect}")
      end

      return number
    end

    protected

    def extract_request_number(resp)
      return (resp["Request"] && resp["Request"]["RequestNumber"])
    end

    def exact_search_request_hash(type, value)
      {
          "PartnershipId" => Defaults.partnership_id,
          "AuthorizationId" => @authorization_id,
          #TODO TODO TODO
          "PickupLocation" => "Milton S. Eisenhower Library",
          "ExactSearch" => [
              {
                  "Type" => type.to_s.upcase,
                  "Value" => value
              }
          ]
      }
    end


  end
end