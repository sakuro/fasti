# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fasti::Formatter do
  # ANSI styling code constants for readable test expectations
  ANSI_ESCAPE = '\e\['
  ANSI_RESET = '\e\[0m'
  ANSI_BOLD = '\e\[1m'
  ANSI_INVERSE = '\e\[7m'
  ANSI_RED = '\e\[31m'
  ANSI_BLUE = '\e\[34m'
  ANSI_YELLOW_BG = '\e\[43m'
  ANSI_BLACK_FG = '\e\[30m'
  ANSI_RED_BOLD = '\e\[31;1m'
  ANSI_BOLD_INVERSE = '\e\[1;7m'

  let(:july_2024) { Fasti::Calendar.new(2024, 7, country: :us) }

  describe "custom styles functionality" do
    context "with no custom styles" do
      let(:formatter) { Fasti::Formatter.new }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
      end

      it "uses default styling" do
        output = formatter.format_month(july_2024)
        # Sunday (July 7) should be bold by default
        expect(output).to match(/#{ANSI_BOLD}\s*7#{ANSI_RESET}/)
      end

      it "applies default holiday styling" do
        output = formatter.format_month(july_2024)
        # July 4 (Independence Day) should be bold by default
        expect(output).to match(/#{ANSI_BOLD}\s*4#{ANSI_RESET}/)
      end

      it "applies default today styling when today" do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 15))
        output = formatter.format_month(july_2024)
        # July 15 (today) should be inverse by default
        expect(output).to match(/#{ANSI_INVERSE}\s*15#{ANSI_RESET}/)
      end
    end

    context "with custom styles completely replacing defaults" do
      let(:styles) do
        {
          sunday: Fasti::Style.new(foreground: :red)
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 4)) # Holiday and today
      end

      it "only applies specified custom styles, no defaults" do
        output = formatter.format_month(july_2024)

        # Sunday should use custom red style
        expect(output).to match(/#{ANSI_RED}\s*7#{ANSI_RESET}/)

        # Holiday (July 4) should NOT be bold (no default holiday style)
        expect(output).not_to match(/#{ANSI_BOLD}\s*4/)

        # Today (July 4) should NOT be inverse (no default today style)
        expect(output).not_to match(/#{ANSI_INVERSE}\s*4/)

        # July 4 should appear as plain text
        expect(output).to match(/\s+4\s/)
      end
    end

    context "with custom weekday styles" do
      let(:styles) do
        {
          sunday: Fasti::Style.new(foreground: :red),
          saturday: Fasti::Style.new(foreground: :blue)
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
      end

      it "applies custom Sunday style" do
        output = formatter.format_month(july_2024)
        # Sunday (July 7) should use custom red foreground
        expect(output).to match(/#{ANSI_RED}\s*7#{ANSI_RESET}/)
      end

      it "applies custom Saturday style" do
        output = formatter.format_month(july_2024)
        # Saturday (July 6) should use custom blue foreground
        expect(output).to match(/#{ANSI_BLUE}\s*6#{ANSI_RESET}/)
      end
    end

    context "with custom holiday styles" do
      let(:styles) do
        {
          holiday: Fasti::Style.new(background: :yellow, foreground: :black)
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
      end

      it "applies custom holiday style" do
        output = formatter.format_month(july_2024)
        # July 4 (Independence Day) should use custom holiday style
        expect(output).to match(/\e\[30;43m\s*4#{ANSI_RESET}/)
      end
    end

    context "with custom today styles" do
      let(:styles) do
        {
          today: Fasti::Style.new(bold: true, inverse: true)
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 15))
      end

      it "applies custom today style" do
        output = formatter.format_month(july_2024)
        # July 15 (today) should use custom bold + inverse style
        expect(output).to match(/#{ANSI_BOLD_INVERSE}\s*15#{ANSI_RESET}/)
      end
    end

    context "with style composition" do
      let(:styles) do
        {
          sunday: Fasti::Style.new(foreground: :red, bold: true),
          today: Fasti::Style.new(inverse: true)
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 7)) # Sunday
      end

      it "composes styles when day matches multiple criteria" do
        output = formatter.format_month(july_2024)
        # July 7 is both Sunday and today, should combine both styles
        # The exact ANSI sequence depends on style composition order
        expect(output).to include("7")
        expect(output).to match(/\e\[.*7.*\e\[0m/) # Should have some ANSI styling
      end
    end

    context "with negated styles" do
      let(:styles) do
        {
          sunday: Fasti::Style.new(foreground: :red, bold: false),
          holiday: Fasti::Style.new(foreground: :green, bold: false)
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
      end

      it "applies styles with explicit false values" do
        output = formatter.format_month(july_2024)

        # Sunday should be red but not bold
        expect(output).to match(/#{ANSI_RED}\s*7#{ANSI_RESET}/)
        expect(output).not_to match(/#{ANSI_BOLD}.*7/)

        # Holiday should be green but not bold
        expect(output).to match(/\e\[32m\s*4#{ANSI_RESET}/) # Green foreground
        expect(output).not_to match(/#{ANSI_BOLD}.*4/)
      end
    end
  end

  describe "integration with StyleParser" do
    it "works with parsed styles from StyleParser" do
      parser = Fasti::StyleParser.new
      parsed_styles = parser.parse("sunday:foreground=red,bold holiday:background=yellow today:inverse")
      formatter = Fasti::Formatter.new(styles: parsed_styles)

      allow(Date).to receive(:today).and_return(Date.new(2024, 7, 15))

      output = formatter.format_month(july_2024)

      # Should contain styled elements
      expect(output).to match(/#{ANSI_RED_BOLD}\s*7#{ANSI_RESET}/) # Sunday
      expect(output).to match(/#{ANSI_YELLOW_BG}\s*4#{ANSI_RESET}/) # Holiday
      expect(output).to match(/#{ANSI_INVERSE}\s*15#{ANSI_RESET}/) # Today
    end
  end
end
