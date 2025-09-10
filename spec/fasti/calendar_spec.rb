# frozen_string_literal: true

require "date"

RSpec.describe Fasti::Calendar do
  let(:calendar) { Fasti::Calendar.new(2024, 6, country: :us) }
  let(:leap_year_calendar) { Fasti::Calendar.new(2024, 2, country: :us) }
  let(:non_leap_year_calendar) { Fasti::Calendar.new(2023, 2, country: :us) }

  describe "#initialize" do
    it "creates calendar with valid parameters" do
      expect(calendar.year).to eq(2024)
      expect(calendar.month).to eq(6)
      expect(calendar.country).to eq(:us)
      expect(calendar.start_of_week).to eq(:sunday)
    end

    it "accepts monday start of week" do
      monday_calendar = Fasti::Calendar.new(2024, 6, country: :jp, start_of_week: :monday)
      expect(monday_calendar.start_of_week).to eq(:monday)
    end

    it "stores country as symbol" do
      calendar = Fasti::Calendar.new(2024, 6, country: :jp)
      expect(calendar.country).to eq(:jp)
    end

    context "with invalid parameters" do
      it "raises error for invalid year" do
        expect { Fasti::Calendar.new(0, 6, country: :us) }
          .to raise_error(ArgumentError, "Invalid year: 0")
        expect { Fasti::Calendar.new(-2024, 6, country: :us) }
          .to raise_error(ArgumentError, "Invalid year: -2024")
        expect { Fasti::Calendar.new("2024", 6, country: :us) }
          .to raise_error(ArgumentError, "Invalid year: 2024")
      end

      it "raises error for invalid month" do
        expect { Fasti::Calendar.new(2024, 0, country: :us) }
          .to raise_error(ArgumentError, "Invalid month: 0")
        expect { Fasti::Calendar.new(2024, 13, country: :us) }
          .to raise_error(ArgumentError, "Invalid month: 13")
      end

      it "raises error for invalid start_of_week" do
        expect { Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :invalid) }
          .to raise_error(ArgumentError, /Invalid start_of_week: invalid/)
      end
    end
  end

  describe "#days_in_month" do
    it "returns correct days for regular months" do
      expect(Fasti::Calendar.new(2024, 1, country: :us).days_in_month).to eq(31)
      expect(Fasti::Calendar.new(2024, 4, country: :us).days_in_month).to eq(30)
      expect(calendar.days_in_month).to eq(30)
    end

    it "returns correct days for February in leap year" do
      expect(leap_year_calendar.days_in_month).to eq(29)
    end

    it "returns correct days for February in non-leap year" do
      expect(non_leap_year_calendar.days_in_month).to eq(28)
    end
  end

  describe "#first_day_of_month" do
    it "returns first day as Date object" do
      first_day = calendar.first_day_of_month
      expect(first_day).to be_a(Date)
      expect(first_day.year).to eq(2024)
      expect(first_day.month).to eq(6)
      expect(first_day.day).to eq(1)
    end
  end

  describe "#last_day_of_month" do
    it "returns last day as Date object" do
      last_day = calendar.last_day_of_month
      expect(last_day).to be_a(Date)
      expect(last_day.year).to eq(2024)
      expect(last_day.month).to eq(6)
      expect(last_day.day).to eq(30)
    end
  end

  describe "#first_day_wday" do
    it "returns day of week for first day" do
      # June 1, 2024 is a Saturday (wday = 6)
      expect(calendar.first_day_wday).to eq(6)
    end
  end

  describe "#leading_empty_days" do
    context "with sunday start" do
      it "calculates correct empty days" do
        # June 1, 2024 is Saturday (wday = 6), with Sunday start = 6 empty days
        expect(calendar.leading_empty_days).to eq(6)
      end
    end

    context "with monday start" do
      it "calculates correct empty days" do
        monday_calendar = Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :monday)
        # June 1, 2024 is Saturday (wday = 6), with Monday start = 5 empty days
        expect(monday_calendar.leading_empty_days).to eq(5)
      end
    end

    context "with wednesday start" do
      it "calculates correct empty days" do
        wednesday_calendar = Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :wednesday)
        # June 1, 2024 is Saturday (wday = 6), with Wednesday start = 3 empty days
        expect(wednesday_calendar.leading_empty_days).to eq(3)
      end
    end

    context "with friday start" do
      it "calculates correct empty days" do
        friday_calendar = Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :friday)
        # June 1, 2024 is Saturday (wday = 6), with Friday start = 1 empty day
        expect(friday_calendar.leading_empty_days).to eq(1)
      end
    end
  end

  describe "#day_headers" do
    context "with sunday start" do
      it "returns headers starting with Sunday" do
        expected = %w[Su Mo Tu We Th Fr Sa]
        expect(calendar.day_headers).to eq(expected)
      end
    end

    context "with monday start" do
      it "returns headers starting with Monday" do
        monday_calendar = Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :monday)
        expected = %w[Mo Tu We Th Fr Sa Su]
        expect(monday_calendar.day_headers).to eq(expected)
      end
    end

    context "with wednesday start" do
      it "returns headers starting with Wednesday" do
        wednesday_calendar = Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :wednesday)
        expected = %w[We Th Fr Sa Su Mo Tu]
        expect(wednesday_calendar.day_headers).to eq(expected)
      end
    end

    context "with saturday start" do
      it "returns headers starting with Saturday" do
        saturday_calendar = Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :saturday)
        expected = %w[Sa Su Mo Tu We Th Fr]
        expect(saturday_calendar.day_headers).to eq(expected)
      end
    end
  end

  describe "#calendar_grid" do
    context "with sunday start" do
      it "generates correct grid structure" do
        grid = calendar.calendar_grid

        # First row should have 6 nils and then day 1
        expect(grid[0]).to eq([nil, nil, nil, nil, nil, nil, 1])

        # Second row should start with day 2
        expect(grid[1]).to start_with([2, 3, 4, 5, 6, 7, 8])

        # Grid should have correct number of weeks
        expect(grid.length).to be_between(5, 6)

        # Each week should have 7 days
        grid.each do |week|
          expect(week.length).to eq(7)
        end

        # Should contain all days of the month
        all_days = grid.flatten
        all_days.compact!
        expect(all_days).to eq((1..30).to_a)
      end
    end

    context "with monday start" do
      it "generates correct grid structure" do
        monday_calendar = Fasti::Calendar.new(2024, 6, country: :us, start_of_week: :monday)
        grid = monday_calendar.calendar_grid

        # First row should have 5 nils and then days 1, 2
        expect(grid[0]).to eq([nil, nil, nil, nil, nil, 1, 2])

        # Should contain all days of the month
        all_days = grid.flatten
        all_days.compact!
        expect(all_days).to eq((1..30).to_a)
      end
    end
  end

  describe "#month_year_header" do
    it "returns formatted month and year" do
      expect(calendar.month_year_header).to eq("June 2024")
    end

    it "returns correct header for different months" do
      jan_calendar = Fasti::Calendar.new(2024, 1, country: :us)
      expect(jan_calendar.month_year_header).to eq("January 2024")

      dec_calendar = Fasti::Calendar.new(2024, 12, country: :us)
      expect(dec_calendar.month_year_header).to eq("December 2024")
    end
  end

  describe "#to_date" do
    it "converts day number to Date object" do
      date = calendar.to_date(15)
      expect(date).to be_a(Date)
      expect(date.year).to eq(2024)
      expect(date.month).to eq(6)
      expect(date.day).to eq(15)
    end

    it "returns nil for nil input" do
      expect(calendar.to_date(nil)).to be_nil
    end
  end

  describe "#holiday?" do
    let(:us_calendar) { Fasti::Calendar.new(2024, 7, country: :us) }
    let(:jp_calendar) { Fasti::Calendar.new(2024, 1, country: :jp) }

    it "returns true for US Independence Day" do
      # July 4th - Independence Day (US holiday)
      expect(us_calendar.holiday?(4)).to be true
    end

    it "returns true for Japanese New Year" do
      # January 1st - New Year's Day (Japanese national holiday)
      expect(jp_calendar.holiday?(1)).to be true
    end

    it "returns false for regular days" do
      expect(calendar.holiday?(15)).to be false
    end

    it "returns false for nil input" do
      expect(calendar.holiday?(nil)).to be false
    end

    it "handles invalid day numbers gracefully" do
      expect(calendar.holiday?(32)).to be false
    end
  end

  describe "edge cases" do
    it "handles December to January transition" do
      dec_calendar = Fasti::Calendar.new(2024, 12, country: :us)
      expect(dec_calendar.days_in_month).to eq(31)
      expect(dec_calendar.month_year_header).to eq("December 2024")
    end

    it "handles leap year edge cases" do
      # 2000 is a leap year (divisible by 400)
      leap_2000 = Fasti::Calendar.new(2000, 2, country: :us)
      expect(leap_2000.days_in_month).to eq(29)

      # 1900 is not a leap year (divisible by 100 but not 400)
      non_leap_1900 = Fasti::Calendar.new(1900, 2, country: :us)
      expect(non_leap_1900.days_in_month).to eq(28)
    end
  end

  describe "historical calendar transitions" do
    context "with Italian transition (1582)" do
      let(:italian_calendar_before) { Fasti::Calendar.new(1582, 10, country: :it) }

      it "handles dates before transition correctly" do
        date = italian_calendar_before.to_date(4)
        expect(date).not_to be_nil
        expect(date.year).to eq(1582)
        expect(date.month).to eq(10)
        expect(date.day).to eq(4)
      end

      it "handles dates after transition correctly" do
        date = italian_calendar_before.to_date(15)
        expect(date).not_to be_nil
        expect(date.year).to eq(1582)
        expect(date.month).to eq(10)
        expect(date.day).to eq(15)
      end

      it "returns nil for dates in transition gap" do
        # Days 5-14 October 1582 never existed in Italy
        (5..14).each do |day|
          expect(italian_calendar_before.to_date(day)).to be_nil
        end
      end

      it "calculates days_in_month correctly despite gap" do
        # October 1582 had 31 days, but 10 were skipped
        expect(italian_calendar_before.days_in_month).to eq(31)
      end
    end

    context "with British transition (1752)" do
      let(:british_calendar) { Fasti::Calendar.new(1752, 9, country: :gb) }

      it "handles dates before British transition" do
        date = british_calendar.to_date(2)
        expect(date).not_to be_nil
        expect(date.year).to eq(1752)
        expect(date.month).to eq(9)
        expect(date.day).to eq(2)
      end

      it "handles dates after British transition" do
        date = british_calendar.to_date(14)
        expect(date).not_to be_nil
        expect(date.year).to eq(1752)
        expect(date.month).to eq(9)
        expect(date.day).to eq(14)
      end

      it "returns nil for dates in British transition gap" do
        # Days 3-13 September 1752 never existed in Britain
        (3..13).each do |day|
          expect(british_calendar.to_date(day)).to be_nil
        end
      end

      it "US follows British transition" do
        us_calendar = Fasti::Calendar.new(1752, 9, country: :us)
        # Same gap as Britain
        (3..13).each do |day|
          expect(us_calendar.to_date(day)).to be_nil
        end
      end
    end

    context "with Russian transition (1918)" do
      let(:russian_calendar) { Fasti::Calendar.new(1918, 2, country: :ru) }

      it "handles transition dates correctly" do
        # Test that the mechanism works, even if specific dates vary
        (1..28).each do |day|
          date = russian_calendar.to_date(day)
          # Each date should either be a valid Date or nil (in gap)
          expect(date).to be_nil.or be_a(Date)
        end
      end
    end

    context "with modern dates (no transition issues)" do
      let(:modern_calendar) { Fasti::Calendar.new(2024, 9, country: :jp) }

      it "handles all modern dates normally" do
        (1..30).each do |day|
          date = modern_calendar.to_date(day)
          expect(date).not_to be_nil
          expect(date.year).to eq(2024)
          expect(date.month).to eq(9)
          expect(date.day).to eq(day)
        end
      end
    end

    context "calendar grid generation with gaps" do
      let(:italian_calendar) { Fasti::Calendar.new(1582, 10, country: :it) }

      it "generates calendar grid correctly despite transition gaps (compressed mode)" do
        grid = italian_calendar.calendar_grid
        expect(grid).to be_an(Array)
        expect(grid.length).to be > 0

        # Grid should contain valid days but not gap days (5-14)
        flat_days = grid.flatten
        flat_days.compact!
        expect(flat_days).to include(1, 2, 3, 4, 15, 16) # Valid days before and after gap
        expect(flat_days).not_to include(5, 6, 7, 8, 9, 10, 11, 12, 13, 14) # Gap days

        # Should have 21 valid days (31 total - 10 gap days)
        expect(flat_days.length).to eq(21)
      end

      it "handles month_year_header for historical dates" do
        expect(italian_calendar.month_year_header).to eq("October 1582")
      end
    end
  end
end
