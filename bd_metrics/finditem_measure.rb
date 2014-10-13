#!/usr/bin/env ruby

# ruby -Ilib:test ./bd_metrics/finditem_measure.rb

require 'borrow_direct'
require 'borrow_direct/find_item'

key        = ARGV[0] || "isbn"
sourcefile = ARGV[1] || File.expand_path("../#{key}.txt", __FILE__)

puts "#{key}: #{sourcefile}"

identifiers = File.readlines(sourcefile).shuffle

puts "  #{identifiers.count} total input identifiers"

times = []
errors = []
finder = BorrowDirect::FindItem.new(ENV["BD_FINDITEM_PATRON"], ENV["BD_LIBRARY_SYMBOL"])


at_exit do
  puts "\n\nERRORS: "
  errors.each do |arr|
    puts arr.inspect
  end
end

i = 0
identifiers.each do |id|
  id = id.chomp
  i = i + 1

  start = Time.now

  begin
    finder.find(key => id)
  rescue BorrowDirect::Error => e
    errors << [key, id, e]
  end
  elapsed = Time.now - start

  times << elapsed
  times.sort!

  if i % 10 == 0
    min       = times[0]
    tenth     = times[(times.count / 10) - 1]
    median    = times[(times.count / 2) - 1]
    ninetieth = times[(times.count - (times.count / 10)) - 1]
    ninetyninth = times[(times.count - (times.count / 100)) - 1]

    max       = times[times.count - 1]

    puts "i==#{i}; min: #{min}; 10th %ile: #{tenth}; median: #{median}; 90th %ile: #{ninetieth}; 99th %ile: #{ninetyninth}; max: #{max}"
    puts "    errors: #{errors.count}"
  end

end

