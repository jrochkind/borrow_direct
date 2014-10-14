require 'json'
require 'httpclient'
require 'ostruct'

require 'borrow_direct/error'

module BorrowDirect
  # Generic abstract BD request, put in a Hash request body, get
  # back a Hash answer. 
  class Request
    attr_accessor :timeout
    attr_reader :last_request_uri, :last_request_json, :last_request_response, :last_request_time

    def initialize(path)
      @api_base = Defaults.api_base
      @api_path = path

      @api_uri = @api_base.chomp("/") + @api_path
    end

    def request(hash)
      http = http_client!

      json_request = JSON.generate(hash)

      # Mostly for debugging, store these
      @last_request_uri = @api_uri
      @last_request_json = json_request      

      start_time = Time.now

      http_response = http.post @api_uri, json_request, {"Content-Type" => "application/json"}

      @last_request_response = http_response
      @last_request_time     = Time.now - start_time

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