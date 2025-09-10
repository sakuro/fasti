# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fasti::Formatter do
  let(:july_2024) { Fasti::Calendar.new(2024, 7, country: :us) }

  describe "custom styles functionality" do
    context "with no custom styles" do
      let(:formatter) { Fasti::Formatter.new }

      it "renders plain text without any styling" do
        output = formatter.format_month(july_2024)
        # Should not contain any ANSI escape sequences
        expect(output).not_to include("\e[")
        expect(output).to include("July 2024")
      end
    end

    context "with custom styles completely replacing defaults" do
      let(:styles) do
        {
          sunday: TIntMe[foreground: :red]
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 4)) # Independence Day (US holiday) and today
      end

      it "only applies specified custom styles, no defaults" do
        output = formatter.format_month(july_2024)

        # Sunday should use custom red style
        expect(output).to contain_styled(:red, /\s*7/)

        # Holiday (July 4) should NOT be bold (no default holiday style)
        expect(output).not_to contain_styled(:bold, /\s*4/, reset: false)

        # Today (July 4) should NOT be inverse (no default today style)
        expect(output).not_to contain_styled(:inverse, /\s*4/, reset: false)

        # July 4 should appear as plain text
        expect(output).to match(/\s+4\s/)
      end
    end

    context "with custom weekday styles" do
      let(:styles) do
        {
          sunday: TIntMe[foreground: :red],
          saturday: TIntMe[foreground: :blue]
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
      end

      it "applies custom Sunday style" do
        output = formatter.format_month(july_2024)
        # Sunday (July 7) should use custom red foreground
        expect(output).to contain_styled(:red, /\s*7/)
      end

      it "applies custom Saturday style" do
        output = formatter.format_month(july_2024)
        # Saturday (July 6) should use custom blue foreground
        expect(output).to contain_styled(:blue, /\s*6/)
      end
    end

    context "with custom holiday styles" do
      let(:styles) do
        {
          holiday: TIntMe[background: :yellow, foreground: :black]
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
      end

      it "applies custom holiday style" do
        output = formatter.format_month(july_2024)
        # July 4 (Independence Day) should use custom holiday style
        expect(output).to contain_styled(:black, :yellow_bg, /\s*4/)
      end
    end

    context "with custom today styles" do
      let(:styles) do
        {
          today: TIntMe[bold: true, inverse: true]
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 15))
      end

      it "applies custom today style" do
        output = formatter.format_month(july_2024)
        # July 15 (today) should use custom bold + inverse style
        expect(output).to contain_styled(:bold, :inverse, /\s*15/)
      end
    end

    context "with style composition" do
      let(:styles) do
        {
          sunday: TIntMe[foreground: :red, bold: true],
          today: TIntMe[inverse: true]
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
          sunday: TIntMe[foreground: :red, bold: false],
          holiday: TIntMe[foreground: :green, bold: false]
        }
      end
      let(:formatter) { Fasti::Formatter.new(styles:) }

      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
      end

      it "applies styles with explicit false values" do
        output = formatter.format_month(july_2024)

        # Sunday should be red but not bold
        expect(output).to contain_styled(:red, /\s*7/)
        expect(output).not_to contain_styled(:bold, /.*7/, reset: false)

        # Holiday should be green but not bold
        expect(output).to match(/\e\[32m\s*4\e\[0m/) # Green foreground
        expect(output).not_to contain_styled(:bold, /.*4/, reset: false)
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
      expect(output).to contain_styled(:red, :bold, /\s*7/) # Sunday
      expect(output).to contain_styled(:yellow_bg, /\s*4/) # Holiday
      expect(output).to contain_styled(:inverse, /\s*15/) # Today
    end
  end
end
