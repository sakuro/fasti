#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
require "bundler/setup"
require "fasti"

# Temporary class to simulate old behavior without caching
class LegacyCalendar < Fasti::Calendar
  # Override to disable caching for benchmark comparison
  def holiday?(day)
    date = to_date(day)
    return false unless date

    begin
      Holidays.on(date, country).any?
    rescue Holidays::InvalidRegion
      false
    rescue
      false
    end
  end
end

def benchmark_month_display(calendar_class, year, month, country, iterations=100)
  calendar = calendar_class.new(year, month, country:)

  Benchmark.realtime do
    iterations.times do
      # Simulate checking all days in the month (like formatter does)
      (1..calendar.days_in_month).each do |day|
        calendar.holiday?(day)
      end
    end
  end
end

def benchmark_year_display(calendar_class, year, country, iterations=10)
  Benchmark.realtime do
    iterations.times do
      (1..12).each do |month|
        calendar = calendar_class.new(year, month, country:)
        (1..calendar.days_in_month).each do |day|
          calendar.holiday?(day)
        end
      end
    end
  end
end

def format_time(seconds)
  if seconds < 0.001
    "#{(seconds * 1_000_000).round(2)}μs"
  elsif seconds < 1
    "#{(seconds * 1000).round(2)}ms"
  else
    "#{seconds.round(3)}s"
  end
end

def format_speedup(old_time, new_time)
  return "N/A" if new_time.zero?

  speedup = old_time / new_time
  "#{speedup.round(2)}x faster"
end

puts "Fasti Holiday Cache Performance Benchmark"
puts "=" * 50
puts

# Test parameters
YEAR = 2024
COUNTRIES = %i[us jp gb].freeze
MONTH_ITERATIONS = 100
YEAR_ITERATIONS = 10

COUNTRIES.each do |country|
  puts "Country: #{country.upcase}"
  puts "-" * 20

  # Month display benchmark
  puts "Month Display (July #{YEAR}, #{MONTH_ITERATIONS} iterations):"

  legacy_month_time = benchmark_month_display(LegacyCalendar, YEAR, 7, country, MONTH_ITERATIONS)
  cached_month_time = benchmark_month_display(Fasti::Calendar, YEAR, 7, country, MONTH_ITERATIONS)

  puts "  Legacy (no cache): #{format_time(legacy_month_time)}"
  puts "  Cached:            #{format_time(cached_month_time)}"
  puts "  Improvement:       #{format_speedup(legacy_month_time, cached_month_time)}"
  puts

  # Year display benchmark
  puts "Year Display (#{YEAR}, #{YEAR_ITERATIONS} iterations):"

  legacy_year_time = benchmark_year_display(LegacyCalendar, YEAR, country, YEAR_ITERATIONS)
  cached_year_time = benchmark_year_display(Fasti::Calendar, YEAR, country, YEAR_ITERATIONS)

  puts "  Legacy (no cache): #{format_time(legacy_year_time)}"
  puts "  Cached:            #{format_time(cached_year_time)}"
  puts "  Improvement:       #{format_speedup(legacy_year_time, cached_year_time)}"
  puts
  puts
end

puts "Benchmark completed!"
puts
puts "Note: Results may vary based on network latency to holiday data sources"
puts "and system performance. Run multiple times for consistent results."
