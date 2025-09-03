# frozen_string_literal: true

require "date"

module Fasti
  # Manages Julian to Gregorian calendar transitions for different countries.
  #
  # This module provides country-specific calendar transition data and validation
  # methods to handle historical calendar reforms. It uses Julian Day Numbers (JDN)
  # for precise date calculations and gap management during transition periods.
  #
  # @example Basic usage
  #   CalendarTransitions.gregorian_start_jdn(:gb)  #=> 2361222
  #   CalendarTransitions.valid_date?(Date.new(1752, 9, 10), :gb)  #=> false (in gap)
  #
  # @example Date creation with country-specific transitions
  #   CalendarTransitions.create_date(1752, 9, 2, :gb)   #=> Date object with British transition
  #   CalendarTransitions.create_date(1582, 10, 4, :it)  #=> Date object with Italian transition
  module CalendarTransitions
    # Calendar transition data mapping countries to their Gregorian adoption dates.
    #
    # Each entry contains the Julian Day Number when the country switched to
    # the Gregorian calendar. This corresponds to Ruby's Date class constants.
    #
    # Key transitions:
    # - Italy (1582): October 4 (Julian) → October 15 (Gregorian) - 10 day gap
    # - Great Britain (1752): September 2 (Julian) → September 14 (Gregorian) - 11 day gap
    # - Russia (1918): January 31 (Julian) → February 14 (Gregorian) - 13 day gap
    # - Greece (1923): February 15 (Julian) → March 1 (Gregorian) - 13 day gap
    TRANSITIONS = {
      # Italy - October 15, 1582 (Gregorian start)
      it: Date::ITALY, # 2299161

      # Great Britain - September 14, 1752 (Gregorian start)
      gb: Date::ENGLAND, # 2361222

      # Common countries using Italian transition (Catholic countries)
      es: Date::ITALY,     # Spain - same as Italy (1582-10-15)
      fr: 2_299_227,       # France - 1582-12-20 (corrected JDN from Wikipedia)
      pt: Date::ITALY,     # Portugal - same as Italy (1582-10-15)
      pl: Date::ITALY,     # Poland - same as Italy (1582-10-15)
      at: Date::ITALY,     # Austria - same as Italy (1582-10-15)

      # Countries using British transition (British influence)
      us: Date::ENGLAND,   # United States - followed British calendar
      ca: Date::ENGLAND,   # Canada - followed British calendar
      au: Date::ENGLAND,   # Australia - followed British calendar
      nz: Date::ENGLAND,   # New Zealand - followed British calendar
      in: Date::ENGLAND,   # India - under British rule

      # Germany (complex - varied by region, using common date)
      de: Date::ITALY, # Most German states adopted in 1582-1584

      # Nordic countries (varied transitions)
      se: 2_361_391,         # Sweden - March 1, 1753 (complex gradual transition)
      dk: 2_342_032,         # Denmark - March 1, 1700
      no: 2_342_032,         # Norway - same as Denmark (March 1, 1700)

      # Eastern European countries (much later adoption)
      ru: 2_421_639,         # Russia - February 14, 1918 (corrected JDN)
      gr: 2_423_410,         # Greece - March 1, 1923 (corrected JDN)

      # Netherlands (complex regional adoption - using latest Protestant adoption)
      nl: 2_342_164, # Netherlands - July 12, 1700 (Gelderland, last province)

      # Additional European countries from historical table
      be: 2_299_245,         # Belgium (Spanish Netherlands) - January 6, 1583
      ch: 2_342_150,         # Switzerland (Protestant cantons) - January 23, 1700
      bg: 2_421_344,         # Bulgaria - April 14, 1916
      ro: 2_421_972,         # Romania - April 14, 1919
      rs: 2_421_972,         # Serbia (Yugoslavia) - April 14, 1919
      hr: 2_421_972,         # Croatia (Yugoslavia) - April 14, 1919
      si: 2_421_972,         # Slovenia (Yugoslavia) - April 14, 1919
      tr: 2_424_858,         # Turkey (civil calendar) - January 1, 1927

      # Recent adopters from non-Julian calendars
      sa: Date::GREGORIAN, # Saudi Arabia - adopted 2016-10-01 (from Islamic/Hijri calendar)

      # Asian countries: transitioned from lunisolar calendars, use proleptic Gregorian for consistency
      # This provides computational consistency while noting historical inaccuracy in documentation
      jp: Date::GREGORIAN,  # Japan adopted Gregorian calendar on 1873-01-01 (Meiji 6)
      cn: Date::GREGORIAN,  # China adopted Gregorian calendar on 1912-01-01 (Republic of China establishment)
      tw: Date::GREGORIAN,  # Taiwan (same historical root as mainland China)
      kr: Date::GREGORIAN,  # Korea adopted Gregorian calendar on 1896-01-01 (Korean Empire, Geonyang 1)
      vn: Date::GREGORIAN,  # Vietnam adopted Gregorian calendar in 1967
      th: Date::GREGORIAN   # Thailand adopted Gregorian calendar on 1888-01-01 (Rattanakosin 107)
    }.freeze
    private_constant :TRANSITIONS

    # Default transition for countries not explicitly listed
    DEFAULT_TRANSITION = Date::ITALY
    private_constant :DEFAULT_TRANSITION

    # Returns the Julian Day Number when the specified country adopted the Gregorian calendar.
    #
    # @param country [Symbol, String] Country code (e.g., :gb, :us, :it)
    # @return [Integer] Julian Day Number of Gregorian calendar adoption
    #
    # @example
    #   CalendarTransitions.gregorian_start_jdn(:gb)  #=> 2361222
    #   CalendarTransitions.gregorian_start_jdn(:it)  #=> 2299161
    #   CalendarTransitions.gregorian_start_jdn(:unknown)  #=> 2299161 (default)
    def self.gregorian_start_jdn(country)
      TRANSITIONS[country.to_sym] || DEFAULT_TRANSITION
    end

    # Creates a Date object using the appropriate calendar system for the given country.
    #
    # This method automatically selects Julian or Gregorian calendar based on
    # the date and country's transition point, ensuring appropriate calendar
    # date representation.
    #
    # @param year [Integer] Year
    # @param month [Integer] Month (1-12)
    # @param day [Integer] Day of month
    # @param country [Symbol, String] Country code
    # @return [Date] Date object with appropriate calendar system
    # @raise [ArgumentError] If the date falls in the transition gap (non-existent)
    #
    # @example
    #   # Before British transition - uses Julian
    #   CalendarTransitions.create_date(1752, 9, 2, :gb)
    #
    #   # After British transition - uses Gregorian
    #   CalendarTransitions.create_date(1752, 9, 14, :gb)
    #
    #   # In gap - raises ArgumentError
    #   CalendarTransitions.create_date(1752, 9, 10, :gb)  # => ArgumentError
    def self.create_date(year, month, day, country)
      transition_jdn = gregorian_start_jdn(country)

      # Try creating the date with Gregorian first (most common case)
      gregorian_date = Date.new(year, month, day, Date::GREGORIAN)

      if gregorian_date.jd >= transition_jdn
        # Date is on or after transition - use Gregorian
        gregorian_date
      else
        # Date is before transition - use Julian
        julian_date = Date.new(year, month, day, Date::JULIAN)

        # Check if this date would fall in the gap
        if julian_date.jd >= transition_jdn
          raise ArgumentError,
            "Date #{year}-#{month.to_s.rjust(2, "0")}-#{day.to_s.rjust(2, "0")} " \
            "does not exist in #{country.upcase} due to calendar transition"
        end

        julian_date
      end
    end

    # Checks if a date exists in the given country's calendar system.
    #
    # During calendar transitions, certain dates were skipped and never existed.
    # This method validates whether a specific date is valid for a country.
    #
    # @param date [Date] Date to validate
    # @param country [Symbol, String] Country code
    # @return [Boolean] true if date exists, false if it falls in transition gap
    #
    # @example
    #   date1 = Date.new(1752, 9, 10)  # In British gap
    #   CalendarTransitions.valid_date?(date1, :gb)  #=> false
    #
    #   date2 = Date.new(1752, 9, 2)   # Before British gap
    #   CalendarTransitions.valid_date?(date2, :gb)  #=> true
    def self.valid_date?(date, country)
      transition_jdn = gregorian_start_jdn(country)

      # If we're dealing with the default transition (Italy), Ruby handles it correctly
      return true if transition_jdn == DEFAULT_TRANSITION && date.jd != transition_jdn - 1

      # For other countries, check if the date falls in a gap
      # We need to check both Julian and Gregorian representations
      begin
        julian_version = Date.new(date.year, date.month, date.day, Date::JULIAN)
        gregorian_version = Date.new(date.year, date.month, date.day, Date::GREGORIAN)

        # If both versions have the same JDN, there's no ambiguity
        return true if julian_version.jd == gregorian_version.jd

        # Check if either version is valid for this country
        julian_valid = julian_version.jd < transition_jdn
        gregorian_valid = gregorian_version.jd >= transition_jdn

        julian_valid || gregorian_valid
      rescue ArgumentError
        # Invalid date in both calendar systems
        false
      end
    end

    # Returns information about a country's calendar transition.
    #
    # @param country [Symbol, String] Country code
    # @return [Hash] Transition information including JDN and gap details
    #
    # @example
    #   CalendarTransitions.transition_info(:gb)
    #   #=> {
    #   #     gregorian_start_jdn: 2361222,
    #   #     gregorian_start_date: #<Date: 1752-09-14>,
    #   #     julian_end_date: #<Date: 1752-09-02>,
    #   #     gap_days: 11
    #   #   }
    def self.transition_info(country)
      transition_jdn = gregorian_start_jdn(country)

      # Use explicit calendar system to avoid implicit Italian transition
      gregorian_start = Date.jd(transition_jdn, Date::GREGORIAN)
      julian_end = Date.jd(transition_jdn - 1, Date::JULIAN)

      # Calculate actual gap in calendar dates, not just JDN difference
      # For example: Oct 4 (Julian) -> Oct 15 (Gregorian) has 10 gap days (5-14)
      if transition_jdn == DEFAULT_TRANSITION
        # For Italy, Ruby's Date class already handles the gap
        gap_days = 10 # Known historical gap for Italy
      else
        # For other countries, calculate based on calendar date differences
        # The gap is the difference between the date numbers minus 1
        gap_days = gregorian_start.day - julian_end.day - 1

        # Handle cross-month transitions (like Denmark Dec 21 -> Jan 1)
        if gap_days < 0
          # When crossing months, need to account for days in the previous month
          # This is a simplified calculation - may need refinement for complex cases
          prev_month_days = Date.new(julian_end.year, julian_end.month, -1, Date::JULIAN).day
          gap_days = (prev_month_days - julian_end.day) + gregorian_start.day - 1
        end
      end

      {
        gregorian_start_jdn: transition_jdn,
        gregorian_start_date: gregorian_start,
        julian_end_date: julian_end,
        gap_days:
      }
    end

    # Returns list of supported countries with transition dates.
    #
    # @return [Array<Symbol>] List of supported country codes
    def self.supported_countries
      TRANSITIONS.keys.sort
    end
  end
end
