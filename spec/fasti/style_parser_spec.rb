# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fasti::StyleParser do
  let(:parser) { Fasti::StyleParser.new }

  describe "#parse" do
    context "with empty or nil input" do
      it "returns empty hash for nil" do
        expect(parser.parse(nil)).to eq({})
      end

      it "returns empty hash for empty string" do
        expect(parser.parse("")).to eq({})
      end

      it "returns empty hash for whitespace-only string" do
        expect(parser.parse("   ")).to eq({})
      end
    end

    context "with simple boolean attributes" do
      it "parses single boolean attribute" do
        result = parser.parse("sunday:bold")
        expect(result[:sunday]).to have_attributes(bold: true)
      end

      it "parses multiple boolean attributes" do
        result = parser.parse("sunday:bold,italic,underline")
        expect(result[:sunday]).to have_attributes(bold: true, italic: true, underline: true)
      end

      it "parses negated attributes" do
        result = parser.parse("sunday:no-bold,no-italic")
        expect(result[:sunday]).to have_attributes(bold: false, italic: false)
      end
    end

    context "with color attributes" do
      it "parses foreground colors" do
        result = parser.parse("sunday:foreground=red")
        expect(result[:sunday]).to have_attributes(foreground: :red)
      end

      it "parses background colors" do
        result = parser.parse("sunday:background=blue")
        expect(result[:sunday]).to have_attributes(background: :blue)
      end

      it "parses hex colors" do
        result = parser.parse("sunday:foreground=#FF0000")
        expect(result[:sunday]).to have_attributes(foreground: "#FF0000")
      end

      it "parses 3-digit hex colors with #" do
        result = parser.parse("sunday:foreground=#F00")
        expect(result[:sunday]).to have_attributes(foreground: "#FF0000")
      end

      it "parses hex colors without #" do
        result = parser.parse("sunday:foreground=FF0000")
        expect(result[:sunday]).to have_attributes(foreground: "#FF0000")
      end

      it "parses 3-digit hex colors without #" do
        result = parser.parse("sunday:foreground=F00")
        expect(result[:sunday]).to have_attributes(foreground: "#FF0000")
      end

      it "parses both foreground and background" do
        result = parser.parse("sunday:foreground=red,background=blue")
        expect(result[:sunday]).to have_attributes(foreground: :red, background: :blue)
      end
    end

    context "with special attribute values" do
      it "parses underline=double" do
        result = parser.parse("sunday:underline=double")
        expect(result[:sunday]).to have_attributes(underline: :double)
      end

      it "raises error for boolean values with equals syntax" do
        expect { parser.parse("sunday:bold=true") }
          .to raise_error(ArgumentError, /Boolean attributes should not use '=' syntax/)
      end
    end

    context "with multiple targets" do
      it "parses multiple different targets" do
        result = parser.parse("sunday:bold monday:italic holiday:foreground=red today:inverse")

        expect(result).to include(
          sunday: have_attributes(bold: true),
          monday: have_attributes(italic: true),
          holiday: have_attributes(foreground: :red),
          today: have_attributes(inverse: true)
        )
      end

      it "handles all weekday targets" do
        style_string = "sunday:bold monday:italic tuesday:underline wednesday:overline thursday:blink friday:conceal saturday:faint"
        result = parser.parse(style_string)

        expect(result).to include(
          sunday: have_attributes(bold: true),
          monday: have_attributes(italic: true),
          tuesday: have_attributes(underline: true),
          wednesday: have_attributes(overline: true),
          thursday: have_attributes(blink: true),
          friday: have_attributes(conceal: true),
          saturday: have_attributes(faint: true)
        )
      end
    end

    context "with complex combinations" do
      it "parses complex style combinations" do
        style_string = "sunday:foreground=red,bold,no-underline holiday:background=yellow,foreground=black,italic today:inverse,bold"
        result = parser.parse(style_string)

        expect(result).to include(
          sunday: have_attributes(foreground: :red, bold: true, underline: false),
          holiday: have_attributes(background: :yellow, foreground: :black, italic: true),
          today: have_attributes(inverse: true, bold: true)
        )
      end
    end

    context "with whitespace handling" do
      it "handles extra whitespace between targets" do
        result = parser.parse("sunday:bold   monday:italic")

        expect(result).to include(
          sunday: have_attributes(bold: true),
          monday: have_attributes(italic: true)
        )
      end

      it "parses attributes without internal spaces" do
        result = parser.parse("sunday:bold,italic")
        expect(result[:sunday]).to have_attributes(bold: true, italic: true)
      end
    end

    context "with validation errors" do
      it "raises error for invalid target" do
        expect { parser.parse("invalid_target:bold") }
          .to raise_error(ArgumentError, /Invalid target: 'invalid_target'/)
      end

      it "raises error for invalid color" do
        expect { parser.parse("sunday:foreground=invalid_color") }
          .to raise_error(ArgumentError, /Invalid color: 'invalid_color'/)
      end

      it "raises error for invalid hex color" do
        expect { parser.parse("sunday:foreground=#ZZZ") }
          .to raise_error(ArgumentError, /Invalid color: '#ZZZ'/)
      end

      it "raises error for invalid boolean attribute" do
        expect { parser.parse("sunday:invalid_attr") }
          .to raise_error(ArgumentError, /Invalid boolean attribute: 'invalid_attr'/)
      end

      it "raises error for invalid entry format" do
        expect { parser.parse("invalid_entry_without_colon") }
          .to raise_error(ArgumentError, /Invalid style entry format/)
      end

      it "raises error for invalid underline value" do
        expect { parser.parse("sunday:underline=invalid") }
          .to raise_error(ArgumentError, /Invalid underline value: 'invalid'/)
      end

      it "raises error for boolean attribute with equals syntax" do
        expect { parser.parse("sunday:bold=maybe") }
          .to raise_error(ArgumentError, /Boolean attributes should not use '=' syntax/)
      end

      it "raises error for spaces around colon in entries" do
        expect { parser.parse("sunday :bold") }
          .to raise_error(ArgumentError, /Invalid style entry format/)
        expect { parser.parse("sunday: bold") }
          .to raise_error(ArgumentError, /Invalid style entry format/)
      end

      it "raises error for whitespace inside entries" do
        # This directly tests parse_entry with whitespace inside
        expect { parser.__send__(:parse_entry, "sunday:foreground =red") }
          .to raise_error(ArgumentError, /Style entry should not contain whitespace/)
        expect { parser.__send__(:parse_entry, "sunday:background= blue") }
          .to raise_error(ArgumentError, /Style entry should not contain whitespace/)
      end
    end
  end

  describe "validation behavior" do
    it "validates targets correctly" do
      # Valid targets should work
      expect { parser.parse("sunday:bold") }.not_to raise_error
      expect { parser.parse("holiday:bold") }.not_to raise_error
      expect { parser.parse("today:bold") }.not_to raise_error

      # Invalid targets should raise error
      expect { parser.parse("invalid_target:bold") }
        .to raise_error(ArgumentError, /Invalid target/)
    end

    it "validates colors correctly" do
      # Valid colors should work
      expect { parser.parse("sunday:foreground=red") }.not_to raise_error
      expect { parser.parse("sunday:foreground=default") }.not_to raise_error

      # Invalid colors should raise error
      expect { parser.parse("sunday:foreground=invalid_color") }
        .to raise_error(ArgumentError, /Invalid color/)
    end

    it "validates boolean attributes correctly" do
      # Valid boolean attributes should work
      expect { parser.parse("sunday:bold") }.not_to raise_error
      expect { parser.parse("sunday:italic") }.not_to raise_error

      # Invalid boolean attributes should raise error
      expect { parser.parse("sunday:invalid_attr") }
        .to raise_error(ArgumentError, /Invalid boolean attribute/)
    end
  end
end
