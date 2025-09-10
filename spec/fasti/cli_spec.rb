# frozen_string_literal: true

require "pathname"
require "tempfile"
require "timecop"

RSpec.describe Fasti::CLI do
  let(:cli) { Fasti::CLI.new }

  # Fix time-dependent tests by freezing time to September 1, 2024
  around do |example|
    Timecop.freeze(Time.new(2024, 9, 1)) do
      example.run
    end
  end

  describe "#run" do
    # Isolate each test from the user's actual config file (~/.config/fasti/config.rb)
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

          Format options:
              -f, --format FORMAT              Output format (month, quarter, year)
              -m, --month                      Display month format (equivalent to --format month)
              -q, --quarter                    Display quarter format (equivalent to --format quarter)
              -y, --year                       Display year format (equivalent to --format year)

          Calendar display options:
              -w, --start-of-week WEEKDAY      Week start day (sunday, monday, tuesday, wednesday, thursday, friday, saturday)
              -c, --country COUNTRY            Country code for holidays (e.g., JP, US, GB, DE)
              -s, --style STYLE                Custom styling (e.g., "sunday:bold holiday:foreground=red today:inverse")

          Configuration options:
                  --config CONFIG_PATH         Specify custom configuration file path
                  --no-config                  Skip configuration file loading (use defaults only)

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

    context "with format shortcut options" do
      it "displays month format using --month" do
        expect { cli.run(%w[6 2024 --month --country US]) }
          .to output(include("June 2024", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "displays month format using -m" do
        expect { cli.run(%w[6 2024 -m --country US]) }
          .to output(include("June 2024", "Su Mo Tu We Th Fr Sa")).to_stdout
      end

      it "displays quarter format using --quarter" do
        expect { cli.run(%w[6 2024 --quarter --country US]) }
          .to output(include("May 2024", "June 2024", "July 2024")).to_stdout
      end

      it "displays quarter format using -q" do
        expect { cli.run(%w[6 2024 -q --country US]) }
          .to output(include("May 2024", "June 2024", "July 2024")).to_stdout
      end

      it "displays year format using --year" do
        expect { cli.run(%w[2024 --year --country US]) }
          .to output(include("2024", "January 2024", "December 2024")).to_stdout
      end

      it "displays year format using -y" do
        expect { cli.run(%w[2024 -y --country US]) }
          .to output(include("2024", "January 2024", "December 2024")).to_stdout
      end

      it "uses last specified option when multiple shortcuts are provided" do
        expect { cli.run(%w[6 2024 --month --quarter --year --country US]) }
          .to output(include("2024", "January 2024", "December 2024")).to_stdout
      end

      it "uses last specified option when mixing shortcuts with --format" do
        expect { cli.run(%w[6 2024 --format month --year --country US]) }
          .to output(include("2024", "January 2024", "December 2024")).to_stdout
      end

      it "uses last specified option when --format comes after shortcuts" do
        expect { cli.run(%w[6 2024 --year --format quarter --country US]) }
          .to output(include("May 2024", "June 2024", "July 2024")).to_stdout
      end

      it "uses last specified option with short flags" do
        expect { cli.run(%w[6 2024 -m -q -y --country US]) }
          .to output(include("2024", "January 2024", "December 2024")).to_stdout
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
      let(:fasti_config_dir) { File.join(config_dir, "fasti") }
      let(:config_file) { File.join(fasti_config_dir, "config.rb") }

      around do |example|
        old_xdg_config_home = ENV["XDG_CONFIG_HOME"]
        ENV["XDG_CONFIG_HOME"] = config_dir
        FileUtils.mkdir_p(fasti_config_dir)
        example.run
      ensure
        ENV["XDG_CONFIG_HOME"] = old_xdg_config_home
        FileUtils.rm_rf(config_dir)
      end

      it "uses config file options" do
        config_content = <<~RUBY
          Fasti.configure do |config|
            config.format = :year
            config.country = :jp
          end
        RUBY
        File.write(config_file, config_content)
        expect { cli.run(%w[]) }
          .to output(include("January", "December")).to_stdout
      end

      it "overrides config file with command line options" do
        config_content = <<~RUBY
          Fasti.configure do |config|
            config.format = :year
            config.country = :jp
          end
        RUBY
        File.write(config_file, config_content)
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
        invalid_content = <<~RUBY
          Fasti.configure do |config|
            config.invalid_option = true
          end
        RUBY
        File.write(config_file, invalid_content)
        expect { cli.run(%w[6 2024 --country US]) }
          .to output(include("Warning:", "June 2024")).to_stdout
      end
    end

    context "with config file options" do
      let(:temp_config_file) { Tempfile.new(["test_config", ".rb"]) }

      after do
        temp_config_file.unlink
      end

      it "uses custom config file with --config option" do
        config_content = <<~RUBY
          Fasti.configure do |config|
            config.format = :year
            config.country = :jp
          end
        RUBY
        temp_config_file.write(config_content)
        temp_config_file.rewind

        expect { cli.run(["--config", temp_config_file.path]) }
          .to output(include("January", "December")).to_stdout
      end

      it "errors when custom config file does not exist" do
        non_existent_path = "/path/that/does/not/exist.rb"
        expect { cli.run(["--config", non_existent_path, "--country", "US"]) }
          .to output(include("Error: Configuration file not found: #{non_existent_path}")).to_stdout
          .and raise_error(SystemExit) {|error| expect(error.status).to eq(1) }
      end

      it "skips config file loading with --no-config option" do
        # Create a default config file that would normally be loaded
        config_dir = ENV["XDG_CONFIG_HOME"] || File.join(Dir.home, ".config")
        fasti_config_dir = File.join(config_dir, "fasti")
        config_file_path = File.join(fasti_config_dir, "config.rb")

        # Create temporary config file to test --no-config
        FileUtils.mkdir_p(fasti_config_dir)
        config_content = <<~RUBY
          Fasti.configure do |config|
            config.format = :year  # This should be ignored with --no-config
            config.country = :jp
          end
        RUBY
        File.write(config_file_path, config_content)

        begin
          # With --no-config, should use month format (default), not year format from config
          expect { cli.run(%w[--no-config --country US 6 2024]) }
            .to output(include("June 2024")).to_stdout
          expect { cli.run(%w[--no-config --country US 6 2024]) }
            .to output {|output| expect(output).not_to include("January", "December") }.to_stdout
        ensure
          FileUtils.rm_f(config_file_path)
          FileUtils.rmdir(fasti_config_dir)
        end
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

  describe "style composition" do
    context "with config file and CLI arguments" do
      let(:config_dir) { Dir.mktmpdir }
      let(:fasti_config_dir) { File.join(config_dir, "fasti") }
      let(:config_file) { File.join(fasti_config_dir, "config.rb") }

      around do |example|
        old_xdg_config_home = ENV["XDG_CONFIG_HOME"]
        ENV["XDG_CONFIG_HOME"] = config_dir
        FileUtils.mkdir_p(fasti_config_dir)

        example.run
      ensure
        ENV["XDG_CONFIG_HOME"] = old_xdg_config_home
        FileUtils.rm_rf(config_dir)
      end

      it "composes styles from config file and CLI arguments" do
        # Config file: sunday is bold
        config_content = <<~RUBY
          Fasti.configure do |config|
            config.style = {
              sunday: { bold: true }
            }
          end
        RUBY
        File.write(config_file, config_content)

        # CLI argument: sunday gets red foreground
        # Expected result: sunday should be both bold and red
        expect { cli.run(%w[--style sunday:foreground=red 9 2024]) }
          .to output(include("\e[31;1m")).to_stdout # red + bold
      end

      it "CLI arguments override config file for same attributes" do
        # Config file: sunday is bold and red
        config_content = <<~RUBY
          Fasti.configure do |config|
            config.style = {
              sunday: { bold: true, foreground: :red }
            }
          end
        RUBY
        File.write(config_file, config_content)

        # CLI argument: sunday gets blue foreground (should override red)
        expect { cli.run(%w[--style sunday:foreground=blue 9 2024]) }
          .to output(include("\e[34;1m")).to_stdout # blue + bold
      end

      it "adds new style targets from CLI to config file styles" do
        # Config file: only sunday style
        config_content = <<~RUBY
          Fasti.configure do |config|
            config.style = {
              sunday: { bold: true }
            }
          end
        RUBY
        File.write(config_file, config_content)

        # CLI argument: add today style (inverse for current day)
        expect { cli.run(%w[--style today:inverse 9 2024]) }
          .to output(/\e\[1;7m\s*1\e\[0m/).to_stdout # Today (Sept 1) with inverse
      end
    end
  end

  describe "error handling" do
    describe "#handle_error" do
      it "can be mocked for testability" do
        # Mock the error handling to avoid process exit during testing
        allow(cli).to receive(:handle_error)

        # This would normally cause an exit, but now we can test it safely
        cli.run(%w[invalid_month 2024 --country US])

        expect(cli).to have_received(:handle_error)
          .with(instance_of(ArgumentError))
      end

      it "outputs error message and exits when not mocked" do
        # Test the actual error handling behavior
        error = ArgumentError.new("Test error message")

        expect { cli.__send__(:handle_error, error) }
          .to output("Error: Test error message\n").to_stdout
          .and raise_error(SystemExit) {|e| expect(e.status).to eq(1) }
      end
    end

    context "when errors occur during execution" do
      it "calls handle_error for parsing errors" do
        allow(cli).to receive(:handle_error)

        # Force a parsing error
        cli.run(%w[abc --country US])

        expect(cli).to have_received(:handle_error)
          .with(instance_of(ArgumentError))
      end

      it "calls handle_error for validation errors" do
        allow(cli).to receive(:handle_error)

        # Force a validation error
        cli.run(%w[13 2024 --country US])

        expect(cli).to have_received(:handle_error)
          .with(instance_of(ArgumentError))
      end
    end
  end
end
