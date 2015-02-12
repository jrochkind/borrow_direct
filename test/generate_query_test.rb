# Encoding: UTF-8

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

  describe "with string arg" do
    it "generates supplied query" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      query = %Q{isbn="#{BorrowDirect::GenerateQuery.escape('1212')}" and (ti="#{BorrowDirect::GenerateQuery.escape('foo')}" or ti="#{BorrowDirect::GenerateQuery.escape('bar')}")}

      url = generate_query.query_url_with(query)

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )
      assert_present url_query
      assert_length 1, url_query["query"]

      assert_equal query, url_query["query"].first
    end
  end

  describe "#normalized_author_title_params" do
    before do
      @generator = BorrowDirect::GenerateQuery.new(@test_base)
    end
    it "raises without good arguments" do
      assert_raises(ArgumentError) {@generator.normalized_author_title_params(nil)}
      assert_raises(ArgumentError) {@generator.normalized_author_title_params({}) }
      assert_raises(ArgumentError) {@generator.normalized_author_title_params({:title => nil}) }
      assert_raises(ArgumentError) {@generator.normalized_author_title_params({:title => ""}) }
    end

    it "passes through simple author and title" do
      author ="John Smith"
      title = "Some Book"
      assert_equal( {:title => "some book", :author => author}, @generator.normalized_author_title_params(:author => author, :title => title))
    end

    it "works with just a title" do
      title  = "Some Book"
      expected = {:title => "some book"}
      assert_equal expected, @generator.normalized_author_title_params(:title => title)
      assert_equal expected, @generator.normalized_author_title_params(:title => title, :author => nil)
      assert_equal expected, @generator.normalized_author_title_params(:title => title, :author => "")
    end

    it "title remove trailing parens" do
      title = "A Book (really bad one)"

      assert_equal( {:title => "a book"}, @generator.normalized_author_title_params(:title => title))
    end

    it "title strip subtitles" do
      assert_equal({:title => "a book"}, @generator.normalized_author_title_params(:title => "A Book: Subtitle"))
      assert_equal({:title => "a book"}, @generator.normalized_author_title_params(:title => "A Book; and more"))
    end

    it "limit to first 5 words" do
      assert_equal({:title => "one two's three four five"}, @generator.normalized_author_title_params(:title => "One Two's Three Four Five Six Seven"))
    end

    it "okay with unicode, strip punct" do
      assert_equal({:title => "el revolución"}, @generator.normalized_author_title_params(:title => "El   Revolución!: Cuban poster art"))
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