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
~~~

Then you can do things, including:

~~~ruby
# default generic patron
BorrowDirect::FindItem.new.bd_requestable?(:isbn => "1212121212")
#=> true or false

# specific patron
BorrowDirect::FindItem.new(patron_barcode).bd_requestable?(:oclc => "121212")
~~~

In error conditions, a BorrowDirect::Error may be thrown -- including request timeouts when
BD is taking too long to respond. You can set timeout value with TBD.

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
