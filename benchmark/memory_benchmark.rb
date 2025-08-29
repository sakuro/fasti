#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "fasti"

# Simple memory measurement helper
def measure_memory_usage
  # Force garbage collection to get accurate measurements
  GC.start
  GC.compact if GC.respond_to?(:compact)

  before = GC.stat[:heap_live_slots]
  yield
  GC.start
  after = GC.stat[:heap_live_slots]

  after - before
end

def format_memory(slots)
  # Rough estimation: each object slot ≈ 40 bytes on 64-bit systems
  bytes = slots * 40
  if bytes < 1024
    "#{bytes}B"
  elsif bytes < 1024 * 1024
    "#{(bytes / 1024.0).round(2)}KB"
  else
    "#{(bytes / (1024.0 * 1024)).round(2)}MB"
  end
end

puts "Fasti Memory Usage Benchmark"
puts "=" * 40
puts

# Test creating calendars and checking holidays
YEAR = 2024
COUNTRIES = %i[us jp gb].freeze

COUNTRIES.each do |country|
  puts "Country: #{country.upcase}"
  puts "-" * 15

  # Single month calendar
  month_memory = measure_memory_usage {
    calendar = Fasti::Calendar.new(YEAR, 7, country:)
    (1..calendar.days_in_month).each {|day| calendar.holiday?(day) }
  }

  # Year worth of calendars (simulating year view)
  year_memory = measure_memory_usage {
    (1..12).each do |month|
      calendar = Fasti::Calendar.new(YEAR, month, country:)
      (1..calendar.days_in_month).each {|day| calendar.holiday?(day) }
    end
  }

  puts "  Single month: #{format_memory(month_memory)}"
  puts "  Full year:    #{format_memory(year_memory)}"
  puts
end

# Test cache behavior - multiple accesses to same month
puts "Cache Efficiency Test"
puts "-" * 20

cache_memory = measure_memory_usage {
  calendar = Fasti::Calendar.new(YEAR, 7, country: :us)

  # First pass - cache gets populated
  (1..calendar.days_in_month).each {|day|
    calendar.holiday?(day)
    # Second pass - should use cache
    calendar.holiday?(day)

    # Third pass - still using cache
    calendar.holiday?(day)
  }
}

puts "Triple access (cache test): #{format_memory(cache_memory)}"
puts
puts "Note: Memory measurements are approximate and may vary"
puts "based on Ruby version and system configuration."
