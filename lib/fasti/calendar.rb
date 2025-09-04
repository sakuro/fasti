# frozen_string_literal: true

require "date"
require "holidays"
require_relative "calendar_transition"

module Fasti
  # Represents a calendar for a specific month and year with configurable start of week.
  #
  # This class provides calendar structure functionality including calendar grid generation,
  # day calculations, and formatting support. It handles different week start preferences
  # (Sunday vs Monday) and integrates with country-specific holiday detection via the holidays gem.
  #
  # @example Creating a calendar for January 2024
  #   calendar = Calendar.new(2024, 1, country: :jp, start_of_week: :sunday)
  #   calendar.days_in_month  #=> 31
  #   calendar.month_year_header  #=> "January 2024"
  #
  # @example Getting calendar grid for display
  #   grid = calendar.calendar_grid
  #   # Returns: [[nil, 1, 2, 3, 4, 5, 6], [7, 8, 9, ...], ...]
  #
  # @example Working with different week starts
  #   sunday_calendar = Calendar.new(2024, 1, country: :us, start_of_week: :sunday)
  #   monday_calendar = Calendar.new(2024, 1, country: :jp, start_of_week: :monday)
  class Calendar
    # @return [Integer] The year of the calendar
    # @return [Integer] The month of the calendar (1-12)
    # @return [Symbol] The start of week preference (:sunday, :monday, :tuesday, etc.)
    # @return [Symbol] The country code for holiday context
    attr_reader :year, :month, :start_of_week, :country

    # Full weekday names for internal reference (as symbols)
    WEEK_DAYS = %i[sunday monday tuesday wednesday thursday friday saturday].freeze
    private_constant :WEEK_DAYS

    # Abbreviated day names for calendar headers
    DAY_ABBREVS = %w[Su Mo Tu We Th Fr Sa].freeze
    private_constant :DAY_ABBREVS

    # Creates a new calendar instance.
    #
    # @param year [Integer] The year (must be positive)
    # @param month [Integer] The month (1-12)
    # @param country [Symbol] Country code for holiday context (e.g., :jp, :us)
    # @param start_of_week [Symbol] Week start preference (:sunday, :monday, :tuesday, etc.)
    # @raise [ArgumentError] If parameters are invalid
    #
    # @example Standard calendar
    #   Calendar.new(2024, 6, country: :jp)
    #
    # @example Monday-start calendar
    #   Calendar.new(2024, 6, country: :us, start_of_week: :monday)
    def initialize(year, month, country:, start_of_week: :sunday)
      @year = year
      @month = month
      @start_of_week = start_of_week.to_sym
      @country = country
      @holidays_for_month = nil
      @calendar_transition = CalendarTransition.new(@country)

      validate_inputs
    end

    # Returns the number of days in the calendar month.
    #
    # @return [Integer] Number of days in the month (28-31)
    #
    # @example
    #   Calendar.new(2024, 2, country: :jp).days_in_month  #=> 29 (leap year)
    #   Calendar.new(2023, 2, country: :jp).days_in_month  #=> 28
    def days_in_month
      Date.new(year, month, -1).day
    end

    # Returns the first day of the calendar month.
    #
    # @return [Date] The first day of the month
    #
    # @example
    #   Calendar.new(2024, 6, country: :jp).first_day_of_month
    #   #=> #<Date: 2024-06-01>
    def first_day_of_month
      @calendar_transition.create_date(year, month, 1)
    rescue ArgumentError
      # If day 1 is in a gap (very rare), try day 2, then 3, etc.
      (2..31).each do |day|
        return @calendar_transition.create_date(year, month, day)
      rescue ArgumentError
        next
      end
      # Fallback to standard Date if all fails
      Date.new(year, month, 1)
    end

    # Returns the last day of the calendar month.
    #
    # @return [Date] The last day of the month
    #
    # @example
    #   Calendar.new(2024, 6, country: :jp).last_day_of_month
    #   #=> #<Date: 2024-06-30>
    def last_day_of_month
      # Start from the theoretical last day and work backwards
      max_days = Date.new(year, month, -1).day
      max_days.downto(1).each do |day|
        return @calendar_transition.create_date(year, month, day)
      rescue ArgumentError
        next
      end
      # Fallback to standard Date if all fails
      Date.new(year, month, -1)
    end

    # Returns the day of the week for the first day of the month.
    #
    # @return [Integer] Day of week (0=Sunday, 1=Monday, ..., 6=Saturday)
    #
    # @example
    #   calendar = Calendar.new(2024, 6, country: :jp)
    #   calendar.first_day_wday  #=> 6 (if June 1st, 2024 is Saturday)
    def first_day_wday
      first_day_of_month.wday
    end

    # Generates a 2D grid representing the calendar layout.
    #
    # The grid is an array of weeks (rows), where each week is an array of 7 days.
    # Days are represented as integers (1-31) or nil for empty cells.
    # The grid respects the start_of_week preference.
    #
    # @return [Array<Array<Integer, nil>>] 2D array of calendar days
    #
    # @example Sunday-start June 2024
    #   calendar = Calendar.new(2024, 6, country: :jp, start_of_week: :sunday)
    #   grid = calendar.calendar_grid
    #   # Returns: [[nil, nil, nil, nil, nil, nil, 1],
    #   #           [2, 3, 4, 5, 6, 7, 8], ...]
    def calendar_grid
      grid = []
      current_row = []

      # Add leading empty cells for days before month starts
      leading_empty_days.times do
        current_row << nil
      end

      # Add only existing days (skip gap days) for continuous display
      (1..days_in_month).each do |day|
        # Only add days that actually exist (not in transition gaps)
        next unless to_date(day)

        current_row << day

        # Start new row on end of week
        if current_row.length == 7
          grid << current_row
          current_row = []
        end
        # Skip gap days completely - they don't take up space in the grid
      end

      # Add trailing empty cells and final row if needed
      if current_row.any?
        current_row << nil while current_row.length < 7
        grid << current_row
      end

      grid
    end

    # Calculates the number of empty cells needed before the first day.
    #
    # This accounts for the start_of_week preference to properly align
    # the first day of the month in the calendar grid.
    #
    # @return [Integer] Number of empty cells (0-6)
    #
    # @example
    #   # If June 1st, 2024 falls on Saturday and we start weeks on Sunday:
    #   calendar = Calendar.new(2024, 6, country: :jp, start_of_week: :sunday)
    #   calendar.leading_empty_days  #=> 6
    def leading_empty_days
      # Calculate offset based on start of week preference
      start_wday = WEEK_DAYS.index(start_of_week) || 0

      (first_day_wday - start_wday) % 7
    end

    # Returns day abbreviations arranged according to start_of_week preference.
    #
    # @return [Array<String>] Array of day abbreviations (Su, Mo, Tu, etc.)
    #
    # @example Sunday start
    #   Calendar.new(2024, 6, country: :jp, start_of_week: :sunday).day_headers
    #   #=> ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    #
    # @example Monday start
    #   Calendar.new(2024, 6, country: :jp, start_of_week: :monday).day_headers
    #   #=> ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    #
    # @example Wednesday start
    #   Calendar.new(2024, 6, country: :jp, start_of_week: :wednesday).day_headers
    #   #=> ["We", "Th", "Fr", "Sa", "Su", "Mo", "Tu"]
    def day_headers
      # Rotate headers based on start of week
      start_wday = WEEK_DAYS.index(start_of_week) || 0

      DAY_ABBREVS.rotate(start_wday)
    end

    # Returns a formatted month and year header string.
    #
    # @return [String] Formatted month and year (e.g., "June 2024")
    #
    # @example
    #   Calendar.new(2024, 6, country: :jp).month_year_header  #=> "June 2024"
    #   Calendar.new(2024, 12, country: :jp).month_year_header #=> "December 2024"
    def month_year_header
      date = first_day_of_month
      date.strftime("%B %Y")
    end

    # Converts a day number to a Date object for this calendar's month/year.
    #
    # @param day [Integer, nil] Day of the month (1-31) or nil
    # @return [Date, nil] Date object for the specified day, or nil if day is nil
    #
    # @example
    #   calendar = Calendar.new(2024, 6, country: :jp)
    #   calendar.to_date(15)  #=> #<Date: 2024-06-15>
    #   calendar.to_date(nil) #=> nil
    def to_date(day)
      return nil unless day
      return nil unless (1..days_in_month).cover?(day)

      begin
        @calendar_transition.create_date(year, month, day)
      rescue ArgumentError
        # Date falls in calendar transition gap (non-existent)
        nil
      end
    end

    # Checks if a specific day in this calendar month is a holiday.
    #
    # @param day [Integer, nil] Day of the month (1-31) or nil
    # @return [Boolean] true if the day is a holiday, false otherwise
    #
    # @example
    #   calendar = Calendar.new(2024, 1, country: :jp)
    #   calendar.holiday?(1)   #=> true (New Year's Day in Japan)
    #   calendar.holiday?(15)  #=> false (regular day)
    #   calendar.holiday?(nil) #=> false
    def holiday?(day)
      date = to_date(day)
      return false unless date

      holidays_for_month.key?(date)
    end

    # Returns a hash of holidays for the current month, keyed by date
    #
    # @return [Hash<Date, Hash>] Hash mapping holiday dates to holiday information
    private def holidays_for_month
      @holidays_for_month ||= begin
        # Use standard Date creation for holidays lookup to avoid recursion
        start_date = Date.new(year, month, 1)
        end_date = Date.new(year, month, -1)

        begin
          holidays = Holidays.between(start_date, end_date, country)
          holidays.each_with_object({}) {|holiday, hash| hash[holiday[:date]] = holiday }
        rescue Holidays::InvalidRegion
          warn "Warning: Unknown country code '#{country}' for holiday detection"
          {}
        rescue => e
          warn "Warning: Holiday detection failed: #{e.message}"
          {}
        end
      end
    end

    private def validate_inputs
      raise ArgumentError, "Invalid year: #{year}" unless year.is_a?(Integer) && year.positive?
      raise ArgumentError, "Invalid month: #{month}" unless (1..12).cover?(month)

      return if WEEK_DAYS.include?(start_of_week)

      raise ArgumentError, "Invalid start_of_week: #{start_of_week}. Must be one of: #{WEEK_DAYS.join(", ")}"
    end
  end
end
