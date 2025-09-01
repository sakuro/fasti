# frozen_string_literal: true

require "pathname"
require "spec_helper"
require "tempfile"

RSpec.describe Fasti::CLI do
  let(:cli) { Fasti::CLI.new }

  describe "#run" do
    # Isolate each test from the user's actual config file (~/.config/fastirc)
    # by redirecting XDG_CONFIG_HOME to a temporary directory.
    # This ensures tests are deterministic and don't depend on external configuration.
    around do |example|
      old_xdg_config_home = ENV["XDG_CONFIG_HOME"]
      temp_config_dir = Dir.mktmpdir
      begin
        ENV["XDG_CONFIG_HOME"] = temp_config_dir
        example.run
      ensure
        ENV["XDG_CONFIG_HOME"] = old_xdg_config_home
        FileUtils.rm_rf(temp_config_dir) if temp_config_dir
      end
    end

    context "with --help option" do
      it "displays help message" do
        expect { cli.run(%w[--help]) }.to output(<<~HELP).to_stdout
          Usage: fasti [month] [year] [options]

          Arguments:
            month  Month (1-12, optional)
            year   Year (optional)

          Calendar display options:
              -f, --format FORMAT              Output format (month, quarter, year)
              -w, --start-of-week WEEKDAY      Week start day (sunday, monday, tuesday, wednesday, thursday, friday, saturday)
              -c, --country COUNTRY            Country code for holidays (e.g., JP, US, GB, DE)
              -s, --style STYLE                Custom styling (e.g., "sunday:bold holiday:foreground=red today:inverse")

          Other options:
              -v, --version                    Show version
              -h, --help                       Show this help
        HELP
      end
    end

    context "with --version option" do
      it "displays version" do
        expect { cli.run(%w[--version]) }.to output(/^\d+\.\d+\.\d+\n$/).to_stdout
      end
    end

    context "with positional arguments" do
      it "displays calendar for specified month and year" do
        expect { cli.run(%w[6 2024 --country US]) }
          .to output(include("June 2024", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "displays calendar for specified month (current year)" do
        current_year = Time.now.year
        expect { cli.run(%w[6 --country US]) }
          .to output(include("June #{current_year}", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "displays calendar for specified year (current month)" do
        expect { cli.run(%w[2024 --country US]) }
          .to output(include("September 2024", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "displays current calendar with no arguments" do
        current_time = Time.now
        current_month_name = current_time.strftime("%B")
        current_year = current_time.year
        expect { cli.run(%w[--country US]) }
          .to output(include("#{current_month_name} #{current_year}", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "interprets single digit argument as month" do
        current_year = Time.now.year
        expect { cli.run(%w[3 --country US]) }
          .to output(include("March #{current_year}", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "interprets large argument as year" do
        expect { cli.run(%w[2023 --country US]) }
          .to output(include("September 2023", "Su Mo Tu We Th Fr Sa")).to_stdout
      end
    end

    context "with quarter format" do
      it "displays three months side by side" do
        expect { cli.run(%w[6 2024 --format quarter --country US]) }
          .to output(include("May 2024", "June 2024", "July 2024")).to_stdout
      end
    end

    context "with year format" do
      it "displays full year calendar" do
        expect { cli.run(%w[2024 --format year --country US]) }
          .to output(include("2024", "January 2024", "December 2024")).to_stdout
      end
    end

    context "with start-of-week option" do
      it "displays calendar with monday start" do
        expect { cli.run(%w[6 2024 --start-of-week monday --country US]) }
          .to output(include("June 2024", "Mo Tu We Th Fr Sa Su")).to_stdout
      end

      it "displays calendar with sunday start" do
        expect { cli.run(%w[6 2024 --start-of-week sunday --country US]) }
          .to output(include("June 2024", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "displays calendar with wednesday start" do
        expect { cli.run(%w[6 2024 --start-of-week wednesday --country US]) }
          .to output(include("June 2024", "We Th Fr Sa Su Mo Tu")).to_stdout
      end

      it "displays calendar with friday start" do
        expect { cli.run(%w[6 2024 --start-of-week friday --country US]) }
          .to output(include("June 2024", "Fr Sa Su Mo Tu We Th")).to_stdout
      end
    end

    context "with invalid arguments" do
      it "returns error for invalid month in two-argument case" do
        expect { cli.run(%w[13 2024 --country US]) }
          .to output(include("Error: Month must be between 1 and 12")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for invalid year" do
        expect { cli.run(%w[6 -1 --country US]) }
          .to output(include("Error: invalid option: -1")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for too many arguments" do
        expect { cli.run(%w[6 2024 extra --country US]) }
          .to output(include("Error: Too many arguments. Expected 0-2, got 3")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for invalid single argument (zero)" do
        expect { cli.run(%w[0 --country US]) }
          .to output(include("Error: Invalid argument: 0. Expected 1-12 (month) or 13+ (year).")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for invalid single argument (negative)" do
        expect { cli.run(%w[-5 --country US]) }
          .to output(include("Error: invalid option: -5")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for non-integer arguments" do
        expect { cli.run(%w[abc --country US]) }
          .to output(include("Error: Invalid argument: 'abc'. Expected integer.")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for invalid month string in two-argument case" do
        expect { cli.run(%w[abc 2024 --country US]) }
          .to output(include("Error: Invalid month: 'abc'")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for invalid year string in two-argument case" do
        expect { cli.run(%w[6 abc --country US]) }
          .to output(include("Error: Invalid year: 'abc'")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "handles edge case: month 12" do
        current_year = Time.now.year
        expect { cli.run(%w[12 --country US]) }
          .to output(include("December #{current_year}")).to_stdout
      end

      it "handles edge case: month 1" do
        current_year = Time.now.year
        expect { cli.run(%w[1 --country US]) }
          .to output(include("January #{current_year}")).to_stdout
      end

      it "interprets 13 as year (boundary test)" do
        expect { cli.run(%w[13 --country US]) }
          .to output(include("September 0013")).to_stdout
      end

      it "returns error for invalid format" do
        expect { cli.run(%w[6 2024 --format invalid --country US]) }
          .to output(include("Error: invalid argument: --format invalid")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "returns error for invalid start-of-week" do
        expect { cli.run(%w[6 2024 --start-of-week invalid --country US]) }
          .to output(include("Error: invalid argument: --start-of-week invalid")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end
    end

    context "with config file" do
      let(:config_dir) { Dir.mktmpdir }
      let(:config_file) { File.join(config_dir, "fastirc") }

      around do |example|
        old_xdg_config_home = ENV["XDG_CONFIG_HOME"]
        ENV["XDG_CONFIG_HOME"] = config_dir
        example.run
      ensure
        ENV["XDG_CONFIG_HOME"] = old_xdg_config_home
        FileUtils.rm_rf(config_dir)
      end

      it "uses config file options" do
        File.write(config_file, "--format year --country JP")
        expect { cli.run(%w[]) }
          .to output(include("January", "December")).to_stdout
      end

      it "overrides config file with command line options" do
        File.write(config_file, "--format year --country JP")
        expect { cli.run(%w[6 2024 --format month]) }
          .to output(include("June 2024")).to_stdout
        expect { cli.run(%w[6 2024 --format month]) }
          .to output {|output| expect(output).not_to include("January") }.to_stdout
      end

      it "handles empty config file" do
        File.write(config_file, "")
        expect { cli.run(%w[6 2024 --country US]) }
          .to output(include("June 2024")).to_stdout
      end

      it "handles invalid config file" do
        File.write(config_file, "--invalid-option")
        expect { cli.run(%w[6 2024 --country US]) }
          .to output(include("Warning:", "June 2024")).to_stdout
      end
    end

    context "with environment locale detection" do
      around do |example|
        old_lc_all = ENV["LC_ALL"]
        old_lang = ENV["LANG"]

        example.run
      ensure
        ENV["LC_ALL"] = old_lc_all
        ENV["LANG"] = old_lang
      end

      it "detects country from LC_ALL" do
        ENV["LC_ALL"] = "ja_JP.UTF-8"
        ENV["LANG"] = "en_US.UTF-8"
        expect { cli.run(%w[1 2024]) }
          .to output(include("January 2024", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "falls back to LANG when LC_ALL is not set" do
        ENV["LC_ALL"] = nil
        ENV["LANG"] = "en_US.UTF-8"
        expect { cli.run(%w[1 2024]) }
          .to output(include("January 2024", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "requires explicit country when environment detection fails" do
        ENV["LC_ALL"] = "C"
        ENV["LANG"] = "POSIX"
        expect { cli.run(%w[1 2024 --format month]) }
          .to output(include("Error: Country could not be determined")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end
    end
  end

  describe "CLI class methods" do
    describe ".run" do
      it "creates instance and calls run" do
        cli_instance = instance_double(Fasti::CLI)
        allow(Fasti::CLI).to receive(:new).and_return(cli_instance)
        allow(cli_instance).to receive(:run)

        Fasti::CLI.run(%w[--help])

        expect(Fasti::CLI).to have_received(:new)
        expect(cli_instance).to have_received(:run).with(%w[--help])
      end
    end
  end
end
