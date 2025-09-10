# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Fasti::Config do
  # Reset configuration before each test
  before do
    Fasti::Config.reset!
  end

  describe ".configure" do
    it "sets configuration values" do
      Fasti.configure do |config|
        config.format = :quarter
        config.start_of_week = :monday
        config.country = :jp
      end

      expect(Fasti.config.format).to eq(:quarter)
      expect(Fasti.config.start_of_week).to eq(:monday)
      expect(Fasti.config.country).to eq(:jp)
    end

    it "converts string values to symbols" do
      Fasti.configure do |config|
        config.format = "year"
        config.start_of_week = "friday"
        config.country = "uk"
      end

      expect(Fasti.config.format).to eq(:year)
      expect(Fasti.config.start_of_week).to eq(:friday)
      expect(Fasti.config.country).to eq(:uk)
    end

    it "handles style configuration with hash format" do
      style_hash = {
        sunday: {bold: true, foreground: :red},
        holiday: {background: :yellow, inverse: true}
      }

      Fasti.configure do |config|
        config.style = style_hash
      end

      expect(Fasti.config.style[:sunday]).to be_a(TIntMe::Style)
      expect(Fasti.config.style[:sunday].bold).to be(true)
      expect(Fasti.config.style[:sunday].foreground).to eq(:red)
      expect(Fasti.config.style[:holiday]).to be_a(TIntMe::Style)
      expect(Fasti.config.style[:holiday].background).to eq(:yellow)
      expect(Fasti.config.style[:holiday].inverse).to be(true)
    end

    it "converts string keys and values in style hash" do
      Fasti.configure do |config|
        config.style = {
          "monday" => {"bold" => "true", "foreground" => "blue"}
        }
      end

      expect(Fasti.config.style[:monday]).to be_a(TIntMe::Style)
      expect(Fasti.config.style[:monday].bold).to be(true)
      expect(Fasti.config.style[:monday].foreground).to eq(:blue)
    end

    it "handles nil style" do
      Fasti.configure do |config|
        config.style = nil
      end

      expect(Fasti.config.style).to be_nil
    end

    it "accepts hex colors in various formats" do
      Fasti.configure do |config|
        config.style = {
          monday: {foreground: "#FF0000"},    # #RRGGBB
          tuesday: {foreground: "#F00"},      # #RGB
          wednesday: {foreground: "FF0000"},  # RRGGBB
          thursday: {foreground: "F00"}       # RGB
        }
      end

      expect(Fasti.config.style[:monday].foreground).to eq("#FF0000")
      expect(Fasti.config.style[:tuesday].foreground).to eq("#F00")
      expect(Fasti.config.style[:wednesday].foreground).to eq("FF0000")
      expect(Fasti.config.style[:thursday].foreground).to eq("F00")
    end

    it "raises error for invalid format" do
      expect {
        Fasti.configure do |config|
          config.format = :invalid
        end
      }.to raise_error(Dry::Types::ConstraintError, /included_in/)
    end

    it "raises error for invalid start_of_week" do
      expect {
        Fasti.configure do |config|
          config.start_of_week = :invalid
        end
      }.to raise_error(Dry::Types::ConstraintError, /included_in/)
    end

    it "raises error for invalid style target" do
      expect {
        Fasti.configure do |config|
          config.style = {invalid_target: {bold: true}}
        end
      }.to raise_error(Dry::Types::ConstraintError, /included_in/)
    end

    it "raises error for invalid style attribute" do
      expect {
        Fasti.configure do |config|
          config.style = {sunday: {invalid_attr: true}}
        end
      }.to raise_error(ArgumentError, /Invalid style attributes/)
    end

    it "raises error for invalid color" do
      expect {
        Fasti.configure do |config|
          config.style = {sunday: {foreground: :invalid_color}}
        end
      }.to raise_error(ArgumentError, /must be Symbol or is in invalid format/)
    end

    it "raises error for non-hash style" do
      expect {
        Fasti.configure do |config|
          config.style = "invalid"
        end
      }.to raise_error(ArgumentError, /Style must be nil or Hash/)
    end

    it "raises error for non-hash style attributes" do
      expect {
        Fasti.configure do |config|
          config.style = {sunday: "not_a_hash"}
        end
      }.to raise_error(ArgumentError, /must be a Hash/)
    end
  end

  describe ".to_h" do
    it "returns current configuration as hash" do
      Fasti.configure do |config|
        config.format = :quarter
        config.country = :jp
        config.style = {sunday: {bold: true}}
      end

      config_hash = Fasti.config.to_h
      expect(config_hash).to eq({
        format: :quarter,
        start_of_week: :sunday, # default
        country: :jp,
        style: {sunday: TIntMe[bold: true]}
      })
    end
  end

  describe ".reset!" do
    it "resets configuration to defaults" do
      # Change from defaults
      Fasti.configure do |config|
        config.format = :year
        config.start_of_week = :monday
        config.country = :jp
        config.style = {sunday: {bold: true}}
      end

      # Reset
      Fasti::Config.reset!

      expect(Fasti.config.format).to eq(:month)
      expect(Fasti.config.start_of_week).to eq(:sunday)
      expect(Fasti.config.country).to eq(:us)
      expect(Fasti.config.style).to be_nil
    end
  end

  describe ".load_from_file" do
    it "loads configuration from Ruby file" do
      config_content = <<~RUBY
        Fasti.configure do |config|
          config.format = :quarter
          config.country = :jp
          config.style = {
            sunday: { bold: true, foreground: :red }
          }
        end
      RUBY

      Tempfile.create(["config", ".rb"]) do |file|
        file.write(config_content)
        file.flush

        config_hash = Fasti::Config.load_from_file(file.path)

        expect(config_hash[:format]).to eq(:quarter)
        expect(config_hash[:country]).to eq(:jp)
        expect(config_hash[:style]).to eq({sunday: TIntMe[bold: true, foreground: :red]})
      end
    end

    it "returns empty hash for non-existent file" do
      config_hash = Fasti::Config.load_from_file("/non/existent/file.rb")
      expect(config_hash).to eq({})
    end

    it "raises ConfigError for invalid Ruby syntax" do
      invalid_content = "invalid ruby syntax {"

      Tempfile.create(["invalid_config", ".rb"]) do |file|
        file.write(invalid_content)
        file.flush

        expect {
          Fasti::Config.load_from_file(file.path)
        }.to raise_error(Fasti::ConfigError, /Invalid Ruby syntax/)
      end
    end

    it "raises ConfigError for runtime errors in config file" do
      error_content = <<~RUBY
        Fasti.configure do |config|
          config.format = :invalid_format
        end
      RUBY

      Tempfile.create(["error_config", ".rb"]) do |file|
        file.write(error_content)
        file.flush

        expect {
          Fasti::Config.load_from_file(file.path)
        }.to raise_error(Fasti::ConfigError, /Error loading configuration/)
      end
    end
  end

  describe "style validation edge cases" do
    it "handles underline with double value" do
      Fasti.configure do |config|
        config.style = {
          today: {underline: :double}
        }
      end

      expect(Fasti.config.style[:today].underline).to eq(:double)
    end

    it "handles underline with boolean values" do
      Fasti.configure do |config|
        config.style = {
          sunday: {underline: true},
          monday: {underline: false}
        }
      end

      expect(Fasti.config.style[:sunday].underline).to be(true)
      expect(Fasti.config.style[:monday].underline).to be(false)
    end

    it "converts string boolean values" do
      Fasti.configure do |config|
        config.style = {
          sunday: {bold: "true", italic: "false"}
        }
      end

      expect(Fasti.config.style[:sunday].bold).to be(true)
      expect(Fasti.config.style[:sunday].italic).to be(false)
    end

    it "handles all supported style targets" do
      targets = %i[sunday monday tuesday wednesday thursday friday saturday holiday today]
      style_hash = targets.each_with_object({}) do |target, hash|
        hash[target] = {bold: true}
      end

      Fasti.configure do |config|
        config.style = style_hash
      end

      expect(Fasti.config.style.keys).to match_array(targets)
    end

    it "handles all supported colors" do
      colors = %i[red blue green yellow magenta cyan white black default]

      colors.each do |color|
        Fasti.configure do |config|
          config.style = {sunday: {foreground: color}}
        end

        expect(Fasti.config.style[:sunday].foreground).to eq(color)
      end
    end
  end
end
