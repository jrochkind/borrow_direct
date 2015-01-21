#!/usr/bin/env ruby

# Quick and dirty script to do some testing. 

# ruby -Ilib:test ./bd_metrics/finditem_measure.rb

require 'borrow_direct'
require 'borrow_direct/find_item'

key = "isbn"
sourcefile = ARGV[0] || File.expand_path("../isbn-bd-test-200.txt", __FILE__)

# How long to wait n BD before giving up. 
timeout = 20

# Range of how long to wait between requests, in seconds. Actual
# delay each time randomly chosen from this range. 
# wait one to 7 minutes. 
delay = 60..420

puts "#{ENV['BD_LIBRARY_SYMBOL']}: #{key}: #{sourcefile}"

identifiers = File.readlines(sourcefile)   #.shuffle
 
puts "  #{identifiers.count} total input identifiers"

times     = []
errors    = []
timeouts  = []

finder = BorrowDirect::FindItem.new(ENV["BD_PATRON"], ENV["BD_LIBRARY_SYMBOL"])
finder.timeout = timeout

i = 0

printresults = lambda do
  times.sort!
  min       = times[0]
  tenth     = times[(times.count / 10) - 1]
  median    = times[(times.count / 2) - 1]
  seventyfifth = times[(times.count - (times.count / 4)) - 1]
  ninetieth = times[(times.count - (times.count / 10)) - 1]
  ninetyninth = times[(times.count - (times.count / 100)) - 1]

  max       = times[times.count - 1]

  puts "\n\n"
  puts "tested #{i} identifiers, with timeout #{timeout}s, delaying #{delay} seconds between FindItem api requests"
  puts "timing min: #{min.round(1)}s; 10th %ile: #{tenth.round(1)}s; median: #{median.round(1)}s; 75th %ile: #{seventyfifth.round(1)}s; 90th %ile: #{ninetieth.round(1)}s; 99th %ile: #{ninetyninth.round(1)}s; max: #{max.round(1)}s"
  puts "    error count: #{errors.count}"
  puts "    timeout count: #{timeouts.count}"
end


at_exit do
  printresults.call

  puts "\n\n\nAll errors: "
  errors.each do |arr|
    puts arr.inspect
  end

  puts "\n\n\nAll timeouts: "
  timeouts.each do |arr|
    puts arr.inspect
  end

  puts "\n\n\n"

end

identifiers.each do |id|
  print "."
  id = id.chomp
  i = i + 1

  start = Time.now

  begin
    finder.find_item_request(key => id)
  rescue BorrowDirect::HttpTimeoutError => e
    timeouts << [key, id, e]
  rescue BorrowDirect::Error => e
    errors << [key, id, e]
  end
  elapsed = Time.now - start

  times << elapsed

  if i % 10 == 0
    printresults.call
  end

  print "w"
  sleep rand(delay)

end

