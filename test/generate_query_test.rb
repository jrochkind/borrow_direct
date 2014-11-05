require 'test_helper'
require 'uri'
require 'cgi'

describe "GenerateQuery" do
  before do
    @test_base = "http://example.org"
  end

  describe "query_url_with" do

    it "raises on unknown field" do
      assert_raises(ArgumentError) do
        BorrowDirect::GenerateQuery.new(@test_base).query_url_with(:invalid_thing => "foo")
      end
    end

    it "generates query" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      url = generate_query.query_url_with(:title => "This is a title", :author => "This is an author")

      assert url.start_with? @test_base

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )

      assert_present url_query

      assert_length 1, url_query["query"]

      query_text = url_query["query"].first

      parts = query_text.split(" and ")

      assert_length 2, parts

      assert_include parts, 'ti="This is a title"'
      assert_include parts, 'au="This is an author"'
    end

    it "ignores nil arguments" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      url = generate_query.query_url_with(:title => "This is a title", :author => nil)

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )

      assert_present url_query

      assert_length 1, url_query["query"]

      query_text = url_query["query"].first

      parts = query_text.split(" and ")

      assert_length 1, parts

      assert_include parts, 'ti="This is a title"'
    end
  end

  describe "best_known_item_query_url_with" do
    it "uses only isbn when available" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      url = generate_query.best_known_item_query_url_with(:isbn => "OUR_ISBN", :title => "This is a title", :author => "This is an author")

      assert url.start_with? @test_base

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )

      assert_present url_query

      assert_length 1, url_query["query"]

      query_text = url_query["query"].first

      parts = query_text.split(" and ")

      assert_length 1, parts

      assert_include parts, 'isbn="OUR_ISBN"'      
    end

    it "uses author and title when it has to" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      url = generate_query.best_known_item_query_url_with(:title => "This is a title", :author => "This is an author")

      assert url.start_with? @test_base

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )

      assert_present url_query

      assert_length 1, url_query["query"]

      query_text = url_query["query"].first

      parts = query_text.split(" and ")

      assert_length 2, parts

      assert_include parts, 'ti="This is a title"'
      assert_include parts, 'au="This is an author"'
    end

    it "can handle nil arguments" do
      url = BorrowDirect::GenerateQuery.new(@html_query_base_url).best_known_item_query_url_with(
             :isbn   => nil,
             :title  => 'the new international economic order',
             :author => nil
      )

      query = assert_bd_query_url(url)

      parts = query.split(" and ")

      assert_include parts, 'ti="the new international economic order"'
    end

  end

  def assert_bd_query_url(url)
    assert_present url

    parsed_url = URI.parse(url)
    url_query  = CGI.parse( parsed_url.query )
    assert_present url_query
    assert_length 1, url_query["query"]

    return url_query["query"].first
  end

end