# frozen_string_literal: true

require "pathname"
require "spec_helper"
require "tempfile"
require "tty-command"

RSpec.describe Fasti::CLI do
  let(:cmd) { TTY::Command.new(printer: :null) }
  let(:exe_path) { File.expand_path("../../exe/fasti", __dir__) }

  describe "#run" do
    context "with --help option" do
      it "displays help message" do
        result = cmd.run("ruby", exe_path, "--help")
        expect(result.out).to include("Usage: fasti [options]")
        expect(result.out).to include("Calendar display options:")
        expect(result.out).to include("--month")
        expect(result.out).to include("--year")
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

    context "with valid month and year" do
      it "displays calendar for specified month" do
        result = cmd.run("ruby", exe_path, "--month", "6", "--year", "2024", "--country", "US")
        expect(result.out).to include("June 2024")
        expect(result.out).to include("Su Mo Tu We Th Fr Sa")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with quarter format" do
      it "displays three months side by side" do
        result = cmd.run("ruby", exe_path, "--format", "quarter", "--month", "6", "--year", "2024", "--country", "US")
        expect(result.out).to include("May 2024")
        expect(result.out).to include("June 2024")
        expect(result.out).to include("July 2024")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with year format" do
      it "displays full year calendar" do
        result = cmd.run("ruby", exe_path, "--format", "year", "--year", "2024", "--country", "US")
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
          "--start-of-week",
          "monday",
          "--month",
          "6",
          "--year",
          "2024",
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
          "--start-of-week",
          "sunday",
          "--month",
          "6",
          "--year",
          "2024",
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
          "--start-of-week",
          "wednesday",
          "--month",
          "6",
          "--year",
          "2024",
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
          "--start-of-week",
          "friday",
          "--month",
          "6",
          "--year",
          "2024",
          "--country",
          "US"
        )
        expect(result.out).to include("Fr Sa Su Mo Tu We Th")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with invalid options" do
      it "returns error for invalid month" do
        expect {
          cmd.run("ruby", exe_path, "--month", "13", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid year" do
        expect {
          cmd.run("ruby", exe_path, "--year", "-1", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid format" do
        expect {
          cmd.run("ruby", exe_path, "--format", "invalid", "--country", "US")
        }.to raise_error(TTY::Command::ExitError) do |error|
          expect(error.to_s).to include("exit status: 1")
        end
      end

      it "returns error for invalid start-of-week" do
        expect {
          cmd.run("ruby", exe_path, "--start-of-week", "invalid", "--country", "US")
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
        result = cmd.run("ruby", exe_path, "--format", "month", "--month", "6", "--year", "2024")
        expect(result.out).to include("June 2024")
        expect(result.out).not_to include("January")
        expect(result.exitstatus).to eq(0)
      end

      it "handles empty config file" do
        File.write(config_file, "")
        result = cmd.run("ruby", exe_path, "--month", "6", "--year", "2024", "--country", "US")
        expect(result.out).to include("June 2024")
        expect(result.exitstatus).to eq(0)
      end

      it "handles invalid config file" do
        File.write(config_file, "--invalid-option")
        result = cmd.run("ruby", exe_path, "--month", "6", "--year", "2024", "--country", "US")
        expect(result.out).to include("Warning:")
        expect(result.out).to include("June 2024")
        expect(result.exitstatus).to eq(0)
      end
    end

    context "with environment locale detection" do
      around do |example|
        old_lc_all = ENV["LC_ALL"]
        old_lang = ENV["LANG"]
        old_xdg_config_home = ENV["XDG_CONFIG_HOME"]

        # Use temporary directory to avoid reading actual config file
        temp_config_dir = Dir.mktmpdir
        ENV["XDG_CONFIG_HOME"] = temp_config_dir

        example.run
      ensure
        ENV["LC_ALL"] = old_lc_all
        ENV["LANG"] = old_lang
        ENV["XDG_CONFIG_HOME"] = old_xdg_config_home
        FileUtils.rm_rf(temp_config_dir) if temp_config_dir
      end

      it "detects country from LC_ALL" do
        ENV["LC_ALL"] = "ja_JP.UTF-8"
        ENV["LANG"] = "en_US.UTF-8"
        result = cmd.run("ruby", exe_path, "--month", "1", "--year", "2024")
        expect(result.exitstatus).to eq(0)
      end

      it "falls back to LANG when LC_ALL is not set" do
        ENV["LC_ALL"] = nil
        ENV["LANG"] = "en_US.UTF-8"
        result = cmd.run("ruby", exe_path, "--month", "1", "--year", "2024")
        expect(result.exitstatus).to eq(0)
      end

      it "requires explicit country when environment detection fails" do
        ENV["LC_ALL"] = "C"
        ENV["LANG"] = "POSIX"
        expect {
          cmd.run("ruby", exe_path, "--format", "month", "--month", "1", "--year", "2024")
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
