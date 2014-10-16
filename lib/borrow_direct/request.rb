require 'json'
require 'httpclient'
require 'ostruct'

require 'borrow_direct'

module BorrowDirect
  # Generic abstract BD request, put in a Hash request body, get
  # back a Hash answer. 
  #  
  #    response_hash = Request.new("/path/to/endpoint").request(request_hash)
  #
  # Typically, clients will use various sub-classes of Request implementing
  # calling of individual BD API's
  # 
  # ## AuthenticationID's
  #
  # Some API endpoints require an "AId"/"AuthencationID". BorrowDirect::Request
  # provides some facilities for managing obtaining such (using Authentication API),
  # usually will be used under the hood by Request subclasses. 
  #
  #     # fetch new auth ID using Authentication API, store it
  #     # in self.auth_id
  #     request.fetch_auth_id!(barcode, library_symbol)  
  #
  #     # return the existing value in self.auth_id, or if
  #     # nil run fetch_auth_id! to fill it out. 
  #     request.need_auth_id(barcode, library_symbol)
  #     
  #     request.auth_id # cached or nil
  class Request
    attr_accessor :timeout
    attr_accessor :auth_id
    attr_reader :last_request_uri, :last_request_json, :last_request_response, :last_request_time

    # Usually an error code from the server will be turned into an exception. 
    # But if there are error codes you expect (usually fixed in a subclass of Request),
    # fill them in this array, and the responses will be returned anyway -- warning,
    # REGARDLESS of HTTP response status code, as these are often non-200 but we want
    # to catch em anyway. 
    attr_accessor :expected_error_codes

    def initialize(path)
      @api_base = Defaults.api_base
      @api_path = path

      @api_uri = @api_base.chomp("/") + @api_path

      @expected_error_codes = []

      @timeout = Defaults.timeout
    end

    def request(hash)
      http = http_client!

      json_request = JSON.generate(hash)

      # Mostly for debugging, store these
      @last_request_uri = @api_uri
      @last_request_json = json_request      

      start_time = Time.now

      http_response = http.post @api_uri, json_request, self.request_headers

      @last_request_response = http_response
      @last_request_time     = Time.now - start_time

      response_hash = begin
        JSON.parse(http_response.body)
      rescue JSON::ParserError => json_parse_exception
        nil
      end
      
      # will be nil if we have none
      einfo = error_info(response_hash)
      expected_error = (einfo && self.expected_error_codes.include?(einfo.number))


      if einfo && (! expected_error)
        raise BorrowDirect::Error.new(einfo.message, einfo.number)      
      elsif http_response.code != 200 && (! expected_error)
        raise BorrowDirect::HttpError.new("HTTP Error: #{http_response.code}: #{http_response.body}")
      elsif response_hash.nil?
        raise BorrowDirect::Error.new("Could not parse expected JSON response: #{http_response.code} #{json_parse_exception}: #{http_response.body}")
      end

      

      return response_hash
    rescue HTTPClient::ReceiveTimeoutError => e
      elapsed = Time.now - start_time
      raise BorrowDirect::HttpTimeoutError.new("Timeout after #{elapsed}s connecting to BorrowDirect server at #{@api_base}")
    end

    # For now, we can send same request headers for all requests. May have to
    # make parameterized later. 
    # Note SOME but not all BD API endpoints REQUIRE User-Agent and 
    # Accept-Language (for no discernable reason)
    def request_headers
      { "Content-Type" => "application/json", 
        "User-Agent" => "ruby borrow_direct gem (#{BorrowDirect::VERSION}) https://github.com/jrochkind/borrow_direct", 
        "Accept-Language" => "en"
      }
    end

    # Fetches new authID, stores it in self.auth_id, overwriting
    # any previous value there. Will raise BorrowDirect::Error if no auth
    # could be fetched. 
    #
    # returns auth_id too. 
    def fetch_auth_id!(barcode, library_symbol)
      self.auth_id = Authentication.new(barcode, library_symbol).get_auth_id
    end

    # Will use value in self.auth_id, or if nil will
    # fetch a value with fetch_auth_id! and return that. 
    def need_auth_id(barcode, library_symbol)
      self.auth_id || fetch_auth_id!(barcode, library_symbol)
    end




    protected

    def http_client!
      http = HTTPClient.new
      if self.timeout
        http.send_timeout    = self.timeout
        http.connect_timeout = self.timeout
        http.receive_timeout    = self.timeout
      end

      return http
    end

    # returns an OpenStruct with #message and #number, 
    # or nil if error info can not be extracted
    def error_info(hash)      
      if hash && (e = hash["Error"]) && (e["ErrorNumber"] || e["ErrorMessage"])
        return OpenStruct.new(:number => e["ErrorNumber"], :message => e["ErrorMessage"])
      end

      # Or wait! Some API's have a totally different way of reporting errors, great!
      if hash && (e = hash["Authentication"]) && e["Problem"] 
        return OpenStruct.new(:number => e["Problem"]["Code"], :message => e["Problem"]["Message"])
      end

      return nil    
    end
  end
end