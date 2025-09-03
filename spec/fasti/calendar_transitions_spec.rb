# frozen_string_literal: true

require "fasti/calendar_transitions"
require "spec_helper"

RSpec.describe Fasti::CalendarTransitions do
  describe ".gregorian_start_jdn" do
    it "returns correct JDN for Italy" do
      expect(Fasti::CalendarTransitions.gregorian_start_jdn(:it)).to eq(Date::ITALY)
    end

    it "returns correct JDN for Great Britain" do
      expect(Fasti::CalendarTransitions.gregorian_start_jdn(:gb)).to eq(Date::ENGLAND)
    end

    it "returns correct JDN for United States (follows British)" do
      expect(Fasti::CalendarTransitions.gregorian_start_jdn(:us)).to eq(Date::ENGLAND)
    end

    it "returns correct JDN for Russia" do
      expect(Fasti::CalendarTransitions.gregorian_start_jdn(:ru)).to eq(2_421_639)
    end

    it "returns default (Italian) JDN for unknown countries" do
      expect(Fasti::CalendarTransitions.gregorian_start_jdn(:unknown)).to eq(Date::ITALY)
    end

    it "accepts string country codes" do
      expect(Fasti::CalendarTransitions.gregorian_start_jdn("gb")).to eq(Date::ENGLAND)
    end
  end

  describe ".create_date" do
    context "with Italian transition (1582)" do
      it "creates Julian dates before transition" do
        date = Fasti::CalendarTransitions.create_date(1582, 10, 4, :it)
        expect(date.year).to eq(1582)
        expect(date.month).to eq(10)
        expect(date.day).to eq(4)
      end

      it "creates Gregorian dates after transition" do
        date = Fasti::CalendarTransitions.create_date(1582, 10, 15, :it)
        expect(date.year).to eq(1582)
        expect(date.month).to eq(10)
        expect(date.day).to eq(15)
      end

      it "raises error for dates in the gap" do
        expect {
          Fasti::CalendarTransitions.create_date(1582, 10, 10, :it)
        }.to raise_error(ArgumentError, /does not exist in IT due to calendar transition/)
      end
    end

    context "with British transition (1752)" do
      it "creates Julian dates before transition" do
        date = Fasti::CalendarTransitions.create_date(1752, 9, 2, :gb)
        expect(date.year).to eq(1752)
        expect(date.month).to eq(9)
        expect(date.day).to eq(2)
      end

      it "creates Gregorian dates after transition" do
        date = Fasti::CalendarTransitions.create_date(1752, 9, 14, :gb)
        expect(date.year).to eq(1752)
        expect(date.month).to eq(9)
        expect(date.day).to eq(14)
      end

      it "raises error for dates in the British gap" do
        expect {
          Fasti::CalendarTransitions.create_date(1752, 9, 10, :gb)
        }.to raise_error(ArgumentError, /does not exist in GB due to calendar transition/)
      end
    end

    context "with modern dates" do
      it "creates modern dates normally" do
        date = Fasti::CalendarTransitions.create_date(2024, 9, 3, :jp)
        expect(date.year).to eq(2024)
        expect(date.month).to eq(9)
        expect(date.day).to eq(3)
      end
    end
  end

  describe ".valid_date?" do
    let(:valid_date) { Date.new(2024, 9, 3) }

    it "returns false for dates in British transition gap" do
      # Ruby's Date class handles Italian transition, so test British gap
      # Create a date that would be in the British gap using default calendar
      british_gap_date = Date.new(1752, 9, 10, Date::ITALY) # Uses Italian calendar, so this date exists
      expect(Fasti::CalendarTransitions.valid_date?(british_gap_date, :gb)).to be false
    end

    it "returns true for valid modern dates" do
      expect(Fasti::CalendarTransitions.valid_date?(valid_date, :jp)).to be true
    end

    it "returns true for dates before transition" do
      before_british = Date.new(1752, 9, 2)
      expect(Fasti::CalendarTransitions.valid_date?(before_british, :gb)).to be true
    end

    it "returns true for dates after transition" do
      after_british = Date.new(1752, 9, 14)
      expect(Fasti::CalendarTransitions.valid_date?(after_british, :gb)).to be true
    end
  end

  describe ".transition_info" do
    it "returns correct information for Great Britain" do
      info = Fasti::CalendarTransitions.transition_info(:gb)

      expect(info[:gregorian_start_jdn]).to eq(Date::ENGLAND)
      expect(info[:gregorian_start_date]).to be_a(Date)
      expect(info[:julian_end_date]).to be_a(Date)
      expect(info[:gap_days]).to be >= 0
    end

    it "returns correct information for Italy" do
      info = Fasti::CalendarTransitions.transition_info(:it)

      expect(info[:gregorian_start_jdn]).to eq(Date::ITALY)
      expect(info[:gregorian_start_date]).to be_a(Date)
      expect(info[:julian_end_date]).to be_a(Date)
      expect(info[:gap_days]).to be >= 0
    end

    it "returns correct information for Russia" do
      info = Fasti::CalendarTransitions.transition_info(:ru)

      expect(info[:gregorian_start_jdn]).to eq(2_421_639)
      expect(info[:gregorian_start_date]).to be_a(Date)
      expect(info[:julian_end_date]).to be_a(Date)
      expect(info[:gap_days]).to be >= 0
    end
  end

  describe ".supported_countries" do
    it "returns array of supported country symbols" do
      countries = Fasti::CalendarTransitions.supported_countries
      expect(countries).to be_an(Array)
      expect(countries).to include(:it, :gb, :us, :jp, :ru)
      expect(countries).to eq(countries.sort)
    end

    it "includes major countries" do
      countries = Fasti::CalendarTransitions.supported_countries
      expect(countries).to include(:us, :gb, :de, :fr, :es, :jp, :ru)
    end
  end

  describe "integration with Date class" do
    it "properly handles Julian Day Number calculations" do
      # Test that our JDN calculations match Ruby's Date constants
      expect(Date.jd(Date::ITALY)).to be_a(Date)
      expect(Date.jd(Date::ENGLAND)).to be_a(Date)

      # Verify that our constants match Ruby's expectations
      expect(Date::ITALY).to be_a(Integer)
      expect(Date::ENGLAND).to be_a(Integer)
      expect(Date::ENGLAND).to be > Date::ITALY
    end
  end
end
