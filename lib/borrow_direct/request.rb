require 'json'
require 'httpclient'
require 'ostruct'

require 'borrow_direct/error'

module BorrowDirect
  # Generic abstract BD request, put in a Hash request body, get
  # back a Hash answer. 
  class Request
    TEST_API_BASE = "https://bdtest.relais-host.com/"
    BD_PARTNERSHIP_ID = "BD"

    def initialize(path)
      @api_base = TEST_API_BASE
      @api_path = path

      @api_uri = @api_base.chomp("/") + @api_path
    end

    def request(hash)
      http = HTTPClient.new

      json_request = JSON.generate(hash)

      start_time = Time.now

      http_response = http.post @api_uri, json_request, {"Content-Type" => "application/json"}

      if http_response.code != 200
        if (einfo = error_info(http_response.body))
          raise BorrowDirect::Error.new(einfo.message, einfo.number)
        end

        raise BorrowDirect::HttpError.new("HTTP Error: #{http_response.code}: #{http_response.body}")
      end

      response_hash = JSON.parse(http_response.body)

      return response_hash
    rescue HTTPClient::ReceiveTimeoutError => e
      elapsed = Time.now - start_time
      raise BorrowDirect::HttpTimeoutError.new("Timeout after #{elapsed}s connecting to BorrowDirect server at #{@api_base}")
    end

    protected

    # returns an OpenStruct with #message and #number, 
    # or nil if error info can not be extracted
    def error_info(response_body)
      hash = JSON.parse(response_body)
      if (e = hash["Error"]) && (e["ErrorNumber"] || e["ErrorMessage"])
        return OpenStruct.new(:number => e["ErrorNumber"], :message => e["ErrorMessage"])
      end
      return nil
    rescue JSON::ParserError
      return nil
    end

  end
end