# frozen_string_literal: true

require "date"
require "paint"
require "spec_helper"

RSpec.describe Fasti::Formatter do
  # ANSI color code constants for readable test expectations
  ANSI_ESCAPE = '\e\['
  ANSI_RESET = '\e\[0m'
  ANSI_RED = '\e\[31m'
  ANSI_BLUE = '\e\[34m'
  ANSI_INVERSE = '\e\[7m'
  ANSI_RED_INVERSE = '\e\[31;7m'
  ANSI_BLUE_INVERSE = '\e\[34;7m'

  let(:formatter) { Fasti::Formatter.new }
  let(:calendar) { Fasti::Calendar.new(2024, 6, country: :us) }
  let(:june_2024) { Fasti::Calendar.new(2024, 6, country: :us) }
  let(:may_2024) { Fasti::Calendar.new(2024, 5, country: :us) }
  let(:july_2024) { Fasti::Calendar.new(2024, 7, country: :us) }

  describe "#initialize" do
    it "creates formatter instance" do
      expect(formatter).to be_a(Fasti::Formatter)
    end
  end

  describe "#format_month" do
    let(:output) { formatter.format_month(calendar) }

    it "includes month and year header" do
      expect(output).to include("June 2024")
    end

    it "includes day headers" do
      expect(output).to include("Su Mo Tu We Th Fr Sa")
    end

    it "includes all days of the month" do
      (1..30).each do |day|
        expect(output).to include(day.to_s)
      end
    end

    it "centers the month header" do
      lines = output.split("\n")
      header_line = lines.first
      expect(header_line).to match(/^\s+June 2024\s+$/)
    end

    it "has correct structure" do
      lines = output.split("\n")
      expect(lines.length).to be >= 8 # Header + blank + day headers + at least 5 weeks
      expect(lines[0]).to include("June 2024") # Month header
      expect(lines[1]).to eq("") # Blank line
      expect(lines[2]).to eq("Su Mo Tu We Th Fr Sa") # Day headers
    end

    context "with Monday start of week" do
      let(:monday_calendar) { Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :monday) }
      let(:output) { formatter.format_month(monday_calendar) }

      it "shows Monday-first day headers" do
        expect(output).to include("Mo Tu We Th Fr Sa Su")
      end
    end
  end

  describe "#format_quarter" do
    let(:calendars) { [may_2024, june_2024, july_2024] }
    let(:output) { formatter.format_quarter(calendars) }

    it "displays three month headers side by side" do
      expect(output).to include("May 2024")
      expect(output).to include("June 2024")
      expect(output).to include("July 2024")

      # Check that headers are on the same line
      lines = output.split("\n")
      header_line = lines.first
      expect(header_line).to include("May 2024")
      expect(header_line).to include("June 2024")
      expect(header_line).to include("July 2024")
    end

    it "displays day headers for all three months" do
      lines = output.split("\n")
      day_header_line = lines[2] # Header, blank, day headers
      expect(day_header_line).to include("Su Mo Tu We Th Fr Sa")
      # Should appear three times (once for each month)
      expect(day_header_line.scan("Su Mo Tu We Th Fr Sa").length).to eq(3)
    end

    it "has correct structure" do
      lines = output.split("\n")
      expect(lines.length).to be >= 8 # Headers + blank + day headers + weeks
      expect(lines[1]).to eq("") # Blank line after headers
    end

    it "raises error with wrong number of calendars" do
      expect { formatter.format_quarter([june_2024]) }
        .to raise_error(ArgumentError, "Expected 3 calendars for quarter view")

      expect { formatter.format_quarter([may_2024, june_2024, july_2024, calendar]) }
        .to raise_error(ArgumentError, "Expected 3 calendars for quarter view")
    end
  end

  describe "#format_year" do
    let(:output) { formatter.format_year(2024, country: :us, start_of_week: :sunday) }

    it "includes year header" do
      expect(output).to include("2024")
    end

    it "includes all 12 months" do
      %w[January February March April May June July August September October November December].each do |month|
        expect(output).to include(month)
      end
    end

    it "has proper year header centering" do
      lines = output.split("\n")
      year_header = lines.first
      expect(year_header).to match(/^\s+2024\s+$/)
    end

    it "displays months in quarters" do
      # Should have 4 quarters separated by blank lines
      quarters = output.split("\n\n")
      expect(quarters.length).to be >= 4
    end

    context "with Monday start of week" do
      let(:monday_output) { formatter.format_year(2024, country: :us, start_of_week: :monday) }

      it "uses Monday start for all months" do
        expect(monday_output).to include("Mo Tu We Th Fr Sa Su")
        # Should not contain Sunday-first headers
        expect(monday_output).not_to include("Su Mo Tu We Th Fr Sa")
      end
    end
  end

  describe "#format_day (private method)" do
    # Test the formatting through public methods that use it
    context "when formatting day through format_month" do
      let(:july_calendar) { Fasti::Calendar.new(2024, 7, country: :us) }
      let(:output) { formatter.format_month(july_calendar) }

      it "formats regular days as right-aligned strings" do
        # Days should appear as right-aligned 2-character strings
        expect(output).to match(/\s+1\s/)
        expect(output).to match(/\s+10\s/)
      end

      it "handles empty cells" do
        # June 2024 starts on Saturday, so first row has 6 empty cells
        lines = output.split("\n")
        calendar_lines = lines[3..] # Skip headers
        first_week = calendar_lines.first
        # Should have spaces for empty cells
        expect(first_week).to match(/^\s+/)
      end
    end

    context "when formatting holiday and weekend" do
      let(:january_calendar) { Fasti::Calendar.new(2024, 1, country: :us) }

      it "applies special formatting to holidays and weekends" do
        # This is hard to test directly due to ANSI codes, but we can verify
        # the output contains Paint formatting
        output = formatter.format_month(january_calendar)
        # The output should contain ANSI escape sequences for colors
        # Should contain some ANSI formatting (holidays/weekends have colors)
        expect(output).to match(/#{ANSI_RED}/) # Should have red for holidays/Sundays
      end
    end

    context "when highlighting today" do
      before do
        # Mock Date.today to control "today" for testing
        allow(Date).to receive(:today).and_return(Date.new(2024, 6, 15))
      end

      it "highlights today's date" do
        output = formatter.format_month(calendar)
        # Should contain ANSI codes for inverse formatting
        # June 15, 2024 is a Saturday, so should have blue + inverse
        expect(output).to match(/#{ANSI_BLUE_INVERSE}\s*15#{ANSI_RESET}/)
      end
    end
  end

  describe "day styling behavior" do
    let(:july_2024) { Fasti::Calendar.new(2024, 7, country: :us) }

    describe "Saturday styling" do
      before do
        # July 6, 2024 is a Saturday (not a holiday)
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1)) # Not today
      end

      it "applies blue color to Saturday when not today" do
        output = formatter.format_month(july_2024)
        # Extract the formatting for day 6 (Saturday)
        # Should contain blue color code (34) but not inverse (7)
        expect(output).to match(/#{ANSI_BLUE}\s*6#{ANSI_RESET}/)
      end

      context "when Saturday is today" do
        before do
          allow(Date).to receive(:today).and_return(Date.new(2024, 7, 6)) # Saturday
        end

        it "applies blue color with inverse formatting" do
          output = formatter.format_month(july_2024)
          # Should contain both blue (34) and inverse (7) codes
          expect(output).to match(/#{ANSI_BLUE_INVERSE}\s*6#{ANSI_RESET}/)
        end
      end
    end

    describe "Sunday styling" do
      before do
        # July 7, 2024 is a Sunday (not a holiday)
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1)) # Not today
      end

      it "applies red color to Sunday when not today" do
        output = formatter.format_month(july_2024)
        # Should contain red color code (31) but not inverse (7)
        expect(output).to match(/#{ANSI_RED}\s*7#{ANSI_RESET}/)
      end

      context "when Sunday is today" do
        before do
          allow(Date).to receive(:today).and_return(Date.new(2024, 7, 7)) # Sunday
        end

        it "applies red color with inverse formatting" do
          output = formatter.format_month(july_2024)
          # Should contain both red (31) and inverse (7) codes
          expect(output).to match(/#{ANSI_RED_INVERSE}\s*7#{ANSI_RESET}/)
        end
      end
    end

    describe "holiday styling" do
      before do
        # July 4, 2024 is Independence Day (Thursday, holiday)
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1)) # Not today
      end

      it "applies red color to holiday when not today" do
        output = formatter.format_month(july_2024)
        # Should contain red color code (31) but not inverse (7)
        expect(output).to match(/#{ANSI_RED}\s*4#{ANSI_RESET}/)
      end

      context "when holiday is today" do
        before do
          allow(Date).to receive(:today).and_return(Date.new(2024, 7, 4)) # Holiday
        end

        it "applies red color with inverse formatting" do
          output = formatter.format_month(july_2024)
          # Should contain both red (31) and inverse (7) codes
          expect(output).to match(/#{ANSI_RED_INVERSE}\s*4#{ANSI_RESET}/)
        end
      end
    end

    describe "holiday on Saturday" do
      # Need to find a Saturday holiday - using a different month/year
      let(:november_2023) { Fasti::Calendar.new(2023, 11, country: :us) }

      before do
        # November 11, 2023 is Veterans Day (Saturday, holiday)
        allow(Date).to receive(:today).and_return(Date.new(2023, 11, 1)) # Not today
      end

      it "applies red color (holiday overrides Saturday blue)" do
        output = formatter.format_month(november_2023)
        # Should contain red color code (31), not blue (34)
        expect(output).to match(/#{ANSI_RED}\s*11#{ANSI_RESET}/)
        # Should not contain blue color for day 11
        expect(output).not_to match(/#{ANSI_BLUE}\s*11#{ANSI_RESET}/)
      end

      context "when holiday Saturday is today" do
        before do
          allow(Date).to receive(:today).and_return(Date.new(2023, 11, 11)) # Holiday Saturday
        end

        it "applies red color with inverse formatting" do
          output = formatter.format_month(november_2023)
          # Should contain both red (31) and inverse (7) codes
          expect(output).to match(/#{ANSI_RED_INVERSE}\s*11#{ANSI_RESET}/)
        end
      end
    end

    describe "regular day styling" do
      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1)) # Not today
      end

      it "applies no color to regular weekday" do
        output = formatter.format_month(july_2024)
        # Day 2 is a Tuesday (regular day) - should appear as plain text
        # Remove all ANSI codes to get clean output for verification
        clean_output = output.gsub(/#{ANSI_ESCAPE}[0-9;]*m/, "")
        expect(clean_output).to match(/\s+2\s/)

        # Verify that day 2 specifically has no ANSI codes around it
        # Look for the pattern where day 2 appears without escape sequences
        expect(output).to match(/\s+2\s+3/) # Day 2 followed by day 3, no ANSI codes
      end

      context "when regular day is today" do
        before do
          allow(Date).to receive(:today).and_return(Date.new(2024, 7, 2)) # Tuesday
        end

        it "applies only inverse formatting" do
          output = formatter.format_month(july_2024)
          # Should contain only inverse (7) code, no color codes
          expect(output).to match(/#{ANSI_INVERSE}\s*2#{ANSI_RESET}/)
          # Should not have any color codes combined with inverse for regular day
          expect(output).not_to match(/#{ANSI_RED_INVERSE}\s*2#{ANSI_RESET}/)
          expect(output).not_to match(/#{ANSI_BLUE_INVERSE}\s*2#{ANSI_RESET}/)
        end
      end
    end
  end

  describe "color coding behavior" do
    let(:january_us) { Fasti::Calendar.new(2024, 1, country: :us) }
    let(:output) { formatter.format_month(january_us) }

    it "applies color formatting to the output" do
      # January 1, 2024 is New Year's Day (holiday) and a Monday
      # The output should contain ANSI color codes
      expect(output).to include("\e[") # ANSI escape sequence
    end

    it "preserves calendar structure with color codes" do
      # Even with color codes, basic structure should be maintained
      expect(output).to include("January 2024")
      expect(output).to include("Su Mo Tu We Th Fr Sa")
    end
  end

  describe "edge cases" do
    it "handles February in leap year" do
      leap_feb = Fasti::Calendar.new(2024, 2, country: :us)
      output = formatter.format_month(leap_feb)
      expect(output).to include("29") # Should include day 29
      expect(output).not_to include("30") # Should not include day 30
    end

    it "handles February in non-leap year" do
      non_leap_feb = Fasti::Calendar.new(2023, 2, country: :us)
      output = formatter.format_month(non_leap_feb)
      expect(output).not_to include("29") # Should not include day 29
    end

    it "handles months with different numbers of days" do
      # Test 31-day month
      march = Fasti::Calendar.new(2024, 3, country: :us)
      march_output = formatter.format_month(march)
      expect(march_output).to include("31")

      # Test 30-day month - check that 31 doesn't appear as a day number
      april = Fasti::Calendar.new(2024, 4, country: :us)
      april_output = formatter.format_month(april)
      # Remove ANSI codes and check for standalone "31"
      clean_output = april_output.gsub(/#{ANSI_ESCAPE}[0-9;]*m/, "")
      expect(clean_output).not_to match(/\b31\b/)
      expect(clean_output).to match(/\b30\b/)
    end
  end
end
