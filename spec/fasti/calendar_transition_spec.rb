# frozen_string_literal: true

RSpec.describe Fasti::CalendarTransition do
  describe ".new" do
    it "creates instance with country symbol" do
      transition = Fasti::CalendarTransition.new(:gb)
      expect(transition.country).to eq(:gb)
    end
  end

  describe "#gregorian_start_jdn" do
    it "returns correct JDN for Italy" do
      transition = Fasti::CalendarTransition.new(:it)
      expect(transition.gregorian_start_jdn).to eq(Date::ITALY)
    end

    it "returns correct JDN for Great Britain" do
      transition = Fasti::CalendarTransition.new(:gb)
      expect(transition.gregorian_start_jdn).to eq(Date::ENGLAND)
    end

    it "returns correct JDN for United States (follows British)" do
      transition = Fasti::CalendarTransition.new(:us)
      expect(transition.gregorian_start_jdn).to eq(Date::ENGLAND)
    end

    it "returns correct JDN for Russia" do
      transition = Fasti::CalendarTransition.new(:ru)
      expect(transition.gregorian_start_jdn).to eq(2_421_639)
    end

    it "returns default (Italian) JDN for unknown countries" do
      transition = Fasti::CalendarTransition.new(:unknown)
      expect(transition.gregorian_start_jdn).to eq(Date::ITALY)
    end
  end

  describe "#create_date" do
    context "with Italian transition (1582)" do
      let(:italy) { Fasti::CalendarTransition.new(:it) }

      it "creates Julian dates before transition" do
        date = italy.create_date(1582, 10, 4)
        expect(date.year).to eq(1582)
        expect(date.month).to eq(10)
        expect(date.day).to eq(4)
      end

      it "creates Gregorian dates after transition" do
        date = italy.create_date(1582, 10, 15)
        expect(date.year).to eq(1582)
        expect(date.month).to eq(10)
        expect(date.day).to eq(15)
      end

      it "raises error for dates in the gap" do
        expect {
          italy.create_date(1582, 10, 10)
        }.to raise_error(ArgumentError, /does not exist in IT due to calendar transition/)
      end
    end

    context "with British transition (1752)" do
      let(:britain) { Fasti::CalendarTransition.new(:gb) }

      it "creates Julian dates before transition" do
        date = britain.create_date(1752, 9, 2)
        expect(date.year).to eq(1752)
        expect(date.month).to eq(9)
        expect(date.day).to eq(2)
      end

      it "creates Gregorian dates after transition" do
        date = britain.create_date(1752, 9, 14)
        expect(date.year).to eq(1752)
        expect(date.month).to eq(9)
        expect(date.day).to eq(14)
      end

      it "raises error for dates in the British gap" do
        expect {
          britain.create_date(1752, 9, 10)
        }.to raise_error(ArgumentError, /does not exist in GB due to calendar transition/)
      end
    end

    context "with modern dates" do
      let(:japan) { Fasti::CalendarTransition.new(:jp) }

      it "creates modern dates normally" do
        date = japan.create_date(2024, 9, 3)
        expect(date.year).to eq(2024)
        expect(date.month).to eq(9)
        expect(date.day).to eq(3)
      end
    end
  end

  describe "#valid_date?" do
    let(:britain) { Fasti::CalendarTransition.new(:gb) }
    let(:japan) { Fasti::CalendarTransition.new(:jp) }
    let(:valid_date) { Date.new(2024, 9, 3) }

    it "returns false for dates in British transition gap" do
      # Ruby's Date class handles Italian transition, so test British gap
      # Create a date that would be in the British gap using default calendar
      british_gap_date = Date.new(1752, 9, 10, Date::ITALY) # Uses Italian calendar, so this date exists
      expect(britain.valid_date?(british_gap_date)).to be false
    end

    it "returns true for valid modern dates" do
      expect(japan.valid_date?(valid_date)).to be true
    end

    it "returns true for dates before transition" do
      before_british = Date.new(1752, 9, 2)
      expect(britain.valid_date?(before_british)).to be true
    end

    it "returns true for dates after transition" do
      after_british = Date.new(1752, 9, 14)
      expect(britain.valid_date?(after_british)).to be true
    end
  end

  describe "#transition_info" do
    it "returns correct information for Great Britain" do
      britain = Fasti::CalendarTransition.new(:gb)
      info = britain.transition_info

      expect(info[:country]).to eq(:gb)
      expect(info[:gregorian_start_jdn]).to eq(Date::ENGLAND)
      expect(info[:gregorian_start_date]).to be_a(Date)
      expect(info[:julian_end_date]).to be_a(Date)
      expect(info[:gap_days]).to be >= 0
    end

    it "returns correct information for Italy" do
      italy = Fasti::CalendarTransition.new(:it)
      info = italy.transition_info

      expect(info[:country]).to eq(:it)
      expect(info[:gregorian_start_jdn]).to eq(Date::ITALY)
      expect(info[:gregorian_start_date]).to be_a(Date)
      expect(info[:julian_end_date]).to be_a(Date)
      expect(info[:gap_days]).to be >= 0
    end

    it "returns correct information for Russia" do
      russia = Fasti::CalendarTransition.new(:ru)
      info = russia.transition_info

      expect(info[:country]).to eq(:ru)
      expect(info[:gregorian_start_jdn]).to eq(2_421_639)
      expect(info[:gregorian_start_date]).to be_a(Date)
      expect(info[:julian_end_date]).to be_a(Date)
      expect(info[:gap_days]).to be >= 0
    end
  end

  describe ".supported_countries" do
    it "returns array of supported country symbols" do
      countries = Fasti::CalendarTransition.supported_countries
      expect(countries).to be_an(Array)
      expect(countries).to include(:it, :gb, :us, :jp, :ru)
      expect(countries).to eq(countries.sort)
    end

    it "includes major countries" do
      countries = Fasti::CalendarTransition.supported_countries
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

  describe "instance caching benefits" do
    it "avoids repeated JDN lookups" do
      transition = Fasti::CalendarTransition.new(:gb)

      # Multiple calls should use cached @transition_jdn
      expect(transition.gregorian_start_jdn).to eq(Date::ENGLAND)
      expect(transition.gregorian_start_jdn).to eq(Date::ENGLAND)
      expect(transition.gregorian_start_jdn).to eq(Date::ENGLAND)
    end

    it "allows multiple operations on same country efficiently" do
      gb = Fasti::CalendarTransition.new(:gb)

      # Multiple date operations without repeated country parameter
      date1 = gb.create_date(1752, 9, 2)
      date2 = gb.create_date(1752, 9, 14)
      info = gb.transition_info

      expect(date1.julian?).to be true
      expect(date2.julian?).to be false
      expect(info[:country]).to eq(:gb)
    end
  end
end
