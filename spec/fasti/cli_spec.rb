# frozen_string_literal: true

require "pathname"
require "spec_helper"
require "tempfile"
require "tty-command"

RSpec.describe Fasti::CLI do
  let(:cmd) { TTY::Command.new(printer: :null) }
  let(:exe_path) { File.expand_path("../../exe/fasti", __dir__) }

  describe "#run" do
    # Isolate each test from the user's actual config file (~/.config/fastirc)
    # by redirecting XDG_CONFIG_HOME to a temporary directory.
    # This ensures tests are deterministic and don't depend on external configuration.
    around do |example|
      old_xdg_config_home = ENV["XDG_CONFIG_HOME"]
      temp_config_dir = Dir.mktmpdir
      ENV["XDG_CONFIG_HOME"] = temp_config_dir
      example.run
    ensure
      ENV["XDG_CONFIG_HOME"] = old_xdg_config_home
      FileUtils.rm_rf(temp_config_dir) if temp_config_dir
    end

    context "with --help option" do
      it "displays help message" do
        result = cmd.run("ruby", exe_path, "--help")
        expect(result.out).to include("Usage: fasti [month] [year] [options]")
        expect(result.out).to include("Arguments:")
        expect(result.out).to include("month  Month (1-12, optional)")
        expect(result.out).to include("year   Year (optional)")
        expect(result.out).to include("Calendar display options:")
        expect(result.out).to include("--format")
        expect(result.out).to include("--start-of-week")
        expect(result.out).to include("--country")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with --version option" do
      it "displays version" do
        result = cmd.run("ruby", exe_path, "--version")
        expect(result.out.strip).to match(/^\d+\.\d+\.\d+/)
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with positional arguments" do
      it "displays calendar for specified month and year" do
        result = cmd.run("ruby", exe_path, "6", "2024", "--country", "US")
        expect(result.out).to include("June 2024")
        expect(result.out).to include("Su Mo Tu We Th Fr Sa")
        expect(result.exitstatus).to eq(0)
      end

      it "displays calendar for specified month (current year)" do
        result = cmd.run("ruby", exe_path, "6", "--country", "US")
        expect(result.out).to include("June")
        expect(result.out).to include("Su Mo Tu We Th Fr Sa")
        expect(result.exitstatus).to eq(0)
      end

      it "displays calendar for specified year (current month)" do
        result = cmd.run("ruby", exe_path, "2024", "--country", "US")
        expect(result.out).to include("2024")
        expect(result.exitstatus).to eq(0)
      end

      it "displays current calendar with no arguments" do
        result = cmd.run("ruby", exe_path, "--country", "US")
        expect(result.exitstatus).to eq(0)
      end

      it "interprets single digit argument as month" do
        result = cmd.run("ruby", exe_path, "3", "--country", "US")
        expect(result.out).to include("March")
        expect(result.exitstatus).to eq(0)
      end

      it "interprets large argument as year" do
        result = cmd.run("ruby", exe_path, "2023", "--country", "US")
        expect(result.out).to include("2023")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with quarter format" do
      it "displays three months side by side" do
        result = cmd.run("ruby", exe_path, "6", "2024", "--format", "quarter", "--country", "US")
        expect(result.out).to include("May 2024")
        expect(result.out).to include("June 2024")
        expect(result.out).to include("July 2024")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with year format" do
      it "displays full year calendar" do
        result = cmd.run("ruby", exe_path, "2024", "--format", "year", "--country", "US")
        expect(result.out).to include("2024")
        expect(result.out).to include("January 2024")
        expect(result.out).to include("December 2024")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with start-of-week option" do
      it "displays calendar with monday start" do
        result = cmd.run(
          "ruby",
          exe_path,
          "6",
          "2024",
          "--start-of-week",
          "monday",
          "--country",
          "US"
        )
        expect(result.out).to include("Mo Tu We Th Fr Sa Su")
        expect(result.exitstatus).to eq(0)
      end

      it "displays calendar with sunday start" do
        result = cmd.run(
          "ruby",
          exe_path,
          "6",
          "2024",
          "--start-of-week",
          "sunday",
          "--country",
          "US"
        )
        expect(result.out).to include("Su Mo Tu We Th Fr Sa")
        expect(result.exitstatus).to eq(0)
      end

      it "displays calendar with wednesday start" do
        result = cmd.run(
          "ruby",
          exe_path,
          "6",
          "2024",
          "--start-of-week",
          "wednesday",
          "--country",
          "US"
        )
        expect(result.out).to include("We Th Fr Sa Su Mo Tu")
        expect(result.exitstatus).to eq(0)
      end

      it "displays calendar with friday start" do
        result = cmd.run(
          "ruby",
          exe_path,
          "6",
          "2024",
          "--start-of-week",
          "friday",
          "--country",
          "US"
        )
        expect(result.out).to include("Fr Sa Su Mo Tu We Th")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with invalid arguments" do
      it "returns error for invalid month in two-argument case" do
        expect {
          cmd.run("ruby", exe_path, "13", "2024", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid year" do
        expect {
          cmd.run("ruby", exe_path, "6", "-1", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for too many arguments" do
        expect {
          cmd.run("ruby", exe_path, "6", "2024", "extra", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid single argument (zero)" do
        expect {
          cmd.run("ruby", exe_path, "0", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid single argument (negative)" do
        expect {
          cmd.run("ruby", exe_path, "-5", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for non-integer arguments" do
        expect {
          cmd.run("ruby", exe_path, "abc", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid month string in two-argument case" do
        expect {
          cmd.run("ruby", exe_path, "abc", "2024", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid year string in two-argument case" do
        expect {
          cmd.run("ruby", exe_path, "6", "abc", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "handles edge case: month 12" do
        result = cmd.run("ruby", exe_path, "12", "--country", "US")
        expect(result.out).to include("December")
        expect(result.exitstatus).to eq(0)
      end

      it "handles edge case: month 1" do
        result = cmd.run("ruby", exe_path, "1", "--country", "US")
        expect(result.out).to include("January")
        expect(result.exitstatus).to eq(0)
      end

      it "returns error for invalid format" do
        expect {
          cmd.run("ruby", exe_path, "6", "2024", "--format", "invalid", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid start-of-week" do
        expect {
          cmd.run("ruby", exe_path, "6", "2024", "--start-of-week", "invalid", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
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
        result = cmd.run("ruby", exe_path)
        expect(result.out).to include("January")
        expect(result.out).to include("December")
        expect(result.exitstatus).to eq(0)
      end

      it "overrides config file with command line options" do
        File.write(config_file, "--format year --country JP")
        result = cmd.run("ruby", exe_path, "6", "2024", "--format", "month")
        expect(result.out).to include("June 2024")
        expect(result.out).not_to include("January")
        expect(result.exitstatus).to eq(0)
      end

      it "handles empty config file" do
        File.write(config_file, "")
        result = cmd.run("ruby", exe_path, "6", "2024", "--country", "US")
        expect(result.out).to include("June 2024")
        expect(result.exitstatus).to eq(0)
      end

      it "handles invalid config file" do
        File.write(config_file, "--invalid-option")
        result = cmd.run("ruby", exe_path, "6", "2024", "--country", "US")
        expect(result.out).to include("Warning:")
        expect(result.out).to include("June 2024")
        expect(result.exitstatus).to eq(0)
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
        result = cmd.run("ruby", exe_path, "1", "2024")
        expect(result.exitstatus).to eq(0)
      end

      it "falls back to LANG when LC_ALL is not set" do
        ENV["LC_ALL"] = nil
        ENV["LANG"] = "en_US.UTF-8"
        result = cmd.run("ruby", exe_path, "1", "2024")
        expect(result.exitstatus).to eq(0)
      end

      it "requires explicit country when environment detection fails" do
        ENV["LC_ALL"] = "C"
        ENV["LANG"] = "POSIX"
        expect {
          cmd.run("ruby", exe_path, "1", "2024", "--format", "month")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("Country could not be determined")
          expect(error.to_s).to include("exit status: 1")
        end
      end
    end
  end

  describe "CLI class methods" do
    describe ".run" do
      it "creates instance and calls run" do
        cli_instance = instance_double(Fasti::CLI)
        allow(Fasti::CLI).to receive(:new).and_return(cli_instance)
        allow(cli_instance).to receive(:run)

        Fasti::CLI.run(["--help"])

        expect(Fasti::CLI).to have_received(:new)
        expect(cli_instance).to have_received(:run).with(["--help"])
      end
    end
  end
end
