module BorrowDirect
  class Error < StandardError
    attr_reader :bd_code, :request_url

    def initialize(msg, bd_code = nil, request_url = nil) 
      @bd_code = bd_code
      @request_url = request_url
      if @bd_code
        msg = "#{@bd_code}: #{msg}"
      end
      super(msg)      
    end
    
  end

  class HttpError < Error ; end
  class HttpTimeoutError < HttpError ; end
end
