module BorrowDirect
  class Error < StandardError
    attr_reader :bd_code

    def initialize(msg, bd_code = nil) 
      @bd_code = bd_code
      if @bd_code
        msg = "#{@bd_code}: #{msg}"
      end
      super(msg)      
    end
    
  end

  class HttpError < Error ; end
  class HttpTimeoutError < HttpError
    attr_reader :timeout
    def initialize(msg, timeout=nil)
      @timeout = timeout
      super(msg)
    end
  end
end
