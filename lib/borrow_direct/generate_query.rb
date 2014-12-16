require 'cgi'

module BorrowDirect
  # Generate a "deep link" to query results in BD's native
  # HTML interface. 
  class GenerateQuery
    attr_accessor :url_base

    # Hash from our own API argument to BD field code
    @@fields = {
      :keyword  => "term",
      :title    => "ti",
      :author   => "au",
      :subject  => "su",
      :isbn     => "isbn",
      :issn     => "issn"
    }

    def initialize(url_base = nil)
      self.url_base = (url_base || BorrowDirect::Defaults.html_base_url)
    end

    # build_query_with(:title => "one two", :author => "three four")
    # valid keys are those supported by BD HTML interface:
    #     :title, :author, :isbn, :subject, :keyword, :isbn, :issn
    #
    # For now, the value is always searched as a phrase, and multiple
    # fields are always 'and'd.  We may enhance/expand later. 
    #
    # Returns an un-escaped query, still needs to be put into a URL
    def build_query_with(options)
      clauses = []

      options.each_pair do |field, value|
        next if value.nil?

        code = @@fields[field]

        raise ArgumentError.new("Don't recognize field code `#{field}`") unless code

        clauses << %Q{#{code}="#{escape value}"}
      end

      return clauses.join(" and ")
    end



    def query_url_with(arg)
      query = arg.kind_of?(Hash) ? build_query_with(arg) : arg.to_s
      
      return add_query_param(self.url_base, "query", query).to_s
    end

    def best_known_item_query_url_with(options)
      raise ArgumentError.new("Need a Hash argument, got #{options.inspect}") unless options.kind_of?(Hash)

      alt_queries = []

      if options[:isbn]
        alt_queries << build_query_with(:isbn => options[:isbn])
      end

      au_ti_parts = []
      if options[:title]
        au_ti_parts << build_query_with(:title => options[:title])
      end
      if options[:author]
        au_ti_parts << build_query_with(:author => options[:author])
      end

      alt_queries << ('(' + au_ti_parts.join(" and ") + ')') if au_ti_parts.length > 0

      if alt_queries.empty?
        raise ArgumentError.new("Not enough information supplied to construct query: #{options.inspect}")
      end

      query = alt_queries.join(" or ")

      return add_query_param(self.url_base, "query", query).to_s
    end

    # Escape a query value. 
    # We don't really know how to escape, for now
    # we just remove double quotes and parens, and replace with spaces. 
    # those seem to cause problems, and that seems to work. 
    def self.escape(str)
      str.gsub(/[")()]/, ' ')
    end
    # Instance method version for convenience. 
    def escape(str)
      self.class.escape(str)
    end

    def add_query_param(uri, key, value)
      uri = URI.parse(uri) unless uri.kind_of? URI

      query_param = "#{CGI.escape key}=#{CGI.escape value}"

      if uri.query
        uri.query += "&" + query_param
      else
        uri.query = query_param
      end
      
      return uri
    end


  end
end