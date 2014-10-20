[![Build Status](https://travis-ci.org/jrochkind/borrow_direct.svg)](https://travis-ci.org/jrochkind/borrow_direct)

# BorrowDirect

EXPERIMENTAL WORK IN PROGRESS, MAY HAVE UNSTABLE API

Ruby tools for programmatic access to BorrowDirect consortial system, powered by Relais D2D software. 

Using API as well as deep-linking to search results and possibly other stuff. 

May also work with other Relais D2D setups with configuration or changes, no idea. 

## Usage

Some configuration at boot, perhaps in a Rails initializer:

~~~ruby
# Uses BD Test system by defualt, if you want to use production system instead
BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_USE

# Set a default BD LibrarySymbol for your library
BorrowDirect::Defaults.library_symbol = "YOURSYMBOL"

# If you want to do FindItem requests with a default generic patron
# barcode
BorrowDirect::Defaults.find_item_patron_barcode = "9999999"

# BorrowDirect can take an awful long time to respond sometimes. 
# How long are you willing to wait? (Seconds, default 30)
BorrowDirect::Defaults.timeout = 10
~~~

Then you can do things. 

### Find an item's requestability (FindItem api)

~~~ruby
# with default generic patron set in config find_item_patron_barcode
response = BorrowDirect::FindItem.new.find?(:isbn => "1212121212")
# Returns a BorrowDirect::FindItem::Response
response.requestable?  
response.pickup_locations

# Or with specific patron, with default library symbol
BorrowDirect::FindItem.new(patron_barcode).find(:isbn => "121212").requestable?
~~~


### Make a request (RequestItem api)
~~~ruby
request_number = BorrowDirect::RequestItem.new(patron_barcode).make_request(pickup_location, :isbn => "1212121212")
# Will return request number, or nil if couldn't be requested. 
# Or, use make_request! (with exclamation point) to raise if
# can't be requested. 
~~~

### Get patron's current requests (RequestQuery api)

~~~ruby
items = BorrowDirect::RequestQuery.new(patron_barcode).requests
# Returns an array of BorrowDirect::RequestQuery::Item
items.each do |item|
   item.request_number
   item.title 
   item.date_submitted # a ruby DateTime
   item.request_status
end

# Or use a BD 'type' argument
BorrowDirect::RequestQuery.new(patron_barcode).requests("open")
~~~

### AuthID's

For BD api that requires an AuthorizationID (RequestItem and RequestQuery), our ruby
API still accepts a barcode. The ruby code will make a separate request to retrieve
the AuthorizationID behind the scenes. 

If you already have an AuthorizationID, you can set it to avoid this, but at the moment
we have no code to rescue from expired authorization ID's (and if we did, depending on
how often they expire, it might be less efficient than simply requesting a new one)

~~~ruby
response = BorrowDirect::FindItem.new(patron_barcode).find(:isbn => isbn)
auth_id  = response.auth_id

BorrowDirect::RequestItem.new(patron_barcode).with_auth_id(auth_id).make_request(pickup_location, :isbn => isbn)
~~~

### Errors

In error conditions, a BorrowDirect::Error may be thrown -- including request timeouts when
BD is taking too long to respond. You can set timeout value with default config, or
for each api object.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'borrow_direct'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install borrow_direct



## Contributing

1. Fork it ( https://github.com/[my-github-username]/borrow_direct/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
