# frozen_string_literal: true

require_relative "style"

module Fasti
  # Handles calendar formatting and display with color-coded output.
  #
  # This class provides various calendar display formats (month, quarter, year)
  # with ANSI color coding for holidays, weekends, and the current date.
  # Holiday detection is handled by the Calendar class using the holidays gem.
  #
  # ## Styling
  # - **Holidays**: Bold text
  # - **Sundays**: Bold text
  # - **Today**: Inverted background/text colors (combined with above styles)
  #
  # @example Basic month formatting
  #   formatter = Formatter.new
  #   calendar = Calendar.new(2024, 6, country: :jp)
  #   puts formatter.format_month(calendar)
  #
  # @example Year view
  #   formatter = Formatter.new
  #   puts formatter.format_year(2024, start_of_week: :sunday, country: :jp)
  class Formatter
    # Default styles for different day types
    # This defines the standard styling behavior when no custom styles are provided
    DEFAULT_STYLES = {
      sunday: Style.new(bold: true),
      holiday: Style.new(bold: true),
      today: Style.new(inverse: true)
    }.freeze
    private_constant :DEFAULT_STYLES

    # Creates a new formatter instance.
    #
    # @param custom_styles [Hash<Symbol, Style>] Custom styles for different day types
    #   Keys can be :sunday, :monday, ..., :saturday, :holiday, :today
    #   If custom_styles is empty, DEFAULT_STYLES will be used
    #   If custom_styles is provided, it completely replaces the defaults
    # @example
    #   Formatter.new  # Uses DEFAULT_STYLES
    #   Formatter.new(custom_styles: { sunday: Style.new(foreground: :red) })  # Only sunday styled
    def initialize(custom_styles: {})
      @styles = custom_styles.empty? ? DEFAULT_STYLES : custom_styles
    end

    # Formats a single month calendar with headers and color coding.
    #
    # Displays the month/year header, day abbreviations, and calendar grid
    # with appropriate color coding for holidays, weekends, and today.
    #
    # @param calendar [Calendar] The calendar to format
    # @return [String] Formatted calendar string with ANSI color codes
    #
    # @example
    #   calendar = Calendar.new(2024, 6, country: :jp)
    #   formatter.format_month(calendar)
    #   # Output:
    #   #      June 2024
    #   #
    #   # Su Mo Tu We Th Fr Sa
    #   #                    1
    #   #  2  3  4  5  6  7  8
    #   # ...
    def format_month(calendar)
      output = []

      # Month/Year header - centered
      header = calendar.month_year_header
      output << header.center(20)
      output << ""

      # Day headers
      output << calendar.day_headers.join(" ")

      # Calendar grid
      calendar.calendar_grid.each do |week|
        week_str = week.map {|day|
          format_day(day, calendar)
        }.join(" ")
        output << week_str
      end

      output.join("\n")
    end

    # Formats three calendars side-by-side in a quarter view.
    #
    # Displays three months horizontally with aligned headers and grids.
    # Typically used for showing current month with adjacent months.
    #
    # @param calendars [Array<Calendar>] Array of exactly 3 calendars to display
    # @return [String] Formatted quarter view string
    # @raise [ArgumentError] If not exactly 3 calendars provided
    #
    # @example Quarter view
    #   calendars = [
    #     Calendar.new(2024, 5, country: :jp),
    #     Calendar.new(2024, 6, country: :jp),
    #     Calendar.new(2024, 7, country: :jp)
    #   ]
    #   formatter.format_quarter(calendars)
    def format_quarter(calendars)
      raise ArgumentError, "Expected 3 calendars for quarter view" unless calendars.length == 3

      output = []

      # Headers for all three months
      headers = calendars.map {|cal| cal.month_year_header.center(20) }
      output << headers.join("  ")
      output << ""

      # Day headers for all three months
      day_headers = calendars.map {|cal| cal.day_headers.join(" ") }
      output << day_headers.join("  ")

      # Calendar grids side by side
      max_rows = calendars.map {|cal| cal.calendar_grid.length }.max

      (0...max_rows).each do |row_index|
        row_parts = calendars.map {|cal|
          if row_index < cal.calendar_grid.length
            week = cal.calendar_grid[row_index]
            week.map {|day| format_day(day, cal) }.join(" ")
          else
            " " * 20 # Empty space for shorter months
          end
        }
        output << row_parts.join("  ")
      end

      output.join("\n")
    end

    # Formats a complete year view with all 12 months in quarters.
    #
    # Displays the full year as 4 quarters, each containing 3 months
    # side-by-side. Each quarter is separated by blank lines.
    #
    # @param year [Integer] The year to display
    # @param start_of_week [Symbol] Week start preference (:sunday or :monday)
    # @param country [String] Country code for holiday context
    # @return [String] Formatted year view string
    #
    # @example Full year display
    #   formatter.format_year(2024, start_of_week: :sunday, country: :jp)
    #   # Displays all 12 months in 4 rows of 3 months each
    def format_year(year, country:, start_of_week: :sunday)
      output = []

      # Year header
      output << year.to_s.center(64)
      output << ""

      # Process 4 quarters (3 months each)
      quarters = []
      (1..12).each_slice(3) do |months|
        calendars = months.map {|month| Calendar.new(year, month, start_of_week:, country:) }
        quarters << format_quarter(calendars)
      end

      output << quarters.join("\n\n")
      output.join("\n")
    end

    # Formats a single day with appropriate color coding.
    #
    # Applies ANSI styling based on the day's characteristics:
    # - Today: Inverted colors (combined with other formatting)
    # - Holidays: Bold text
    # - Sundays: Bold text
    # - Regular days: No special formatting
    #
    # @param day [Integer, nil] Day of the month (1-31) or nil for empty cells
    # @param calendar [Calendar] Calendar context for date conversion
    # @return [String] Formatted day string with ANSI codes, right-aligned to 2 characters
    #
    # @example
    #   format_day(15, calendar)    #=> "15" (regular day)
    #   format_day(1, calendar)     #=> styled " 1" with bold text (if Sunday/holiday)
    #   format_day(nil, calendar)   #=> "  " (empty cell)
    private def format_day(day, calendar)
      return "  " unless day

      day_str = day.to_s.rjust(2)
      date = calendar.to_date(day)

      # Build style through composition based on day characteristics
      style = Style.new # Start with default style

      # 1. Apply day-of-week style
      weekday_key = %i[sunday monday tuesday wednesday thursday friday saturday][date.wday]
      if @styles.key?(weekday_key)
        style >>= @styles[weekday_key]
      end

      # 2. Apply holiday style
      if calendar.holiday?(day) && @styles.key?(:holiday)
        style >>= @styles[:holiday]
      end

      # 3. Apply today style
      if date == Date.today && @styles.key?(:today)
        style >>= @styles[:today]
      end

      # 4. Apply the composed style
      style.call(day_str)
    end
  end
end
