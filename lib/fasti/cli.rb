# frozen_string_literal: true

require "locale"
require "optparse"
require "pathname"
require "shellwords"

module Fasti
  # Immutable data structure for CLI options
  Options = Data.define(:month, :year, :format, :start_of_week, :country, :style)

  # Command-line interface for the fasti calendar application.
  #
  # This class handles all CLI functionality including option parsing, validation,
  # and calendar generation. It supports various display formats and customization
  # options while maintaining backwards compatibility.
  #
  # ## Options
  # - `--month, -m`: Month to display (1-12, default: current month)
  # - `--year, -y`: Year to display (default: current year)
  # - `--format, -f`: Display format (month/quarter/year, default: month)
  # - `--start-of-week, -w`: Week start (sunday/monday, default: sunday)
  # - `--country, -c`: Country code for holidays (auto-detected from LANG/LC_ALL, supports many countries)
  # - `--style, -s`: Custom styling for different day types (e.g., "sunday:bold holiday:foreground=red")
  # - `--version, -v`: Show version information
  # - `--help, -h`: Show help message
  #
  # ## Configuration File
  # Default options can be specified in a configuration file:
  # - Path: `$XDG_CONFIG_HOME/fastirc` (or `$HOME/.config/fastirc` if XDG_CONFIG_HOME is unset)
  # - Format: Shell-style arguments (e.g., `--format year --country US`)
  # - Precedence: Command line options override config file options
  #
  # @example Basic usage
  #   CLI.run(["--month", "6", "--year", "2024"])
  #
  # @example Year view
  #   CLI.run(["--format", "year", "--country", "US"])
  #
  # @example Config file content ($HOME/.config/fastirc)
  #   --format quarter --start-of-week monday --country US
  class CLI
    # Runs the CLI with the specified arguments.
    #
    # @param argv [Array<String>] Command line arguments to parse
    def self.run(argv)
      new.run(argv)
    end

    # Runs the CLI instance with the specified arguments.
    #
    # @param argv [Array<String>] Command line arguments to parse
    def run(argv)
      catch(:early_exit) do
        options = parse_options(argv)
        generate_calendar(options)
      end
    rescue => e
      puts "Error: #{e.message}"
      exit 1
    end

    # Parses command line options using OptionParser.
    #
    # @param argv [Array<String>] Arguments to parse
    # @return [Options] Parsed options object
    private def parse_options(argv)
      options = default_options
      options_hash = options.to_h
      parser = create_option_parser(options_hash, include_help: true)
      parser.parse!(argv)

      # Create new Options object with parsed values
      parsed_options = Options.new(**options_hash)

      # Validate required options
      unless parsed_options.country
        raise ArgumentError,
          "Country could not be determined. Use --country with a country code (e.g., JP, US, GB, DE) or set LANG/LC_ALL environment variables"
      end

      parsed_options
    end

    # Returns default option values merged with config file settings.
    #
    # @return [Options] Default options
    private def default_options
      current_time = Time.now
      defaults = {
        month: current_time.month,
        year: current_time.year,
        format: :month,
        start_of_week: :sunday,
        country: detect_country_from_environment,
        style: nil
      }

      # Merge with config file options if available
      config_options = load_config_options
      merged_options = defaults.merge(config_options)

      Options.new(**merged_options)
    end

    # Loads options from the config file if it exists.
    #
    # @return [Hash] Config options or empty hash if no config file
    private def load_config_options
      config_file = config_file_path
      return {} unless config_file.exist?

      begin
        content = config_file.read.strip
        return {} if content.empty?

        # Parse config file content as shell arguments
        config_args = Shellwords.split(content)
        parse_config_args(config_args)
      rescue => e
        puts "Warning: Failed to parse config file #{config_file}: #{e.message}"
        {}
      end
    end

    # Determines the config file path using XDG specification.
    #
    # @return [Pathname] Path to config file
    private def config_file_path
      config_home = ENV["XDG_CONFIG_HOME"] || (Pathname.new(Dir.home) / ".config")
      Pathname.new(config_home) / "fastirc"
    end

    # Creates a shared OptionParser for both CLI and config file parsing.
    #
    # @param options [Hash] Hash to store parsed options
    # @param include_help [Boolean] Whether to include help and version options
    # @return [OptionParser] Configured option parser
    private def create_option_parser(options, include_help:)
      OptionParser.new do |opts|
        # Register custom type converters
        opts.accept(Symbol) {|value| value.to_sym }
        opts.accept(:downcase_symbol) { it.downcase.to_sym }
        if include_help
          opts.banner = "Usage: fasti [options]"
          opts.separator ""
          opts.separator "Calendar display options:"
        end

        opts.on("-m", "--month MONTH", Integer, "Month (1-12, default: current)") do |month|
          validate_month!(month)
          options[:month] = month
        end

        opts.on("-y", "--year YEAR", Integer, "Year (default: current)") do |year|
          validate_year!(year)
          options[:year] = year
        end

        opts.on(
          "-f",
          "--format FORMAT",
          %w[month quarter year],
          Symbol,
          "Output format (month, quarter, year)"
        ) do |format|
          options[:format] = format
        end

        opts.on(
          "-w",
          "--start-of-week WEEKDAY",
          %w[sunday monday tuesday wednesday thursday friday saturday],
          Symbol,
          "Week start day (sunday, monday, tuesday, wednesday, thursday, friday, saturday)"
        ) do |weekday|
          options[:start_of_week] = weekday
        end

        opts.on(
          "-c",
          "--country COUNTRY",
          :downcase_symbol,
          "Country code for holidays (e.g., JP, US, GB, DE)"
        ) do |country|
          options[:country] = country
        end

        opts.on(
          "-s",
          "--style STYLE",
          String,
          "Custom styling (e.g., \"sunday:bold holiday:foreground=red today:inverse\")"
        ) do |style|
          options[:style] = style
        end

        if include_help
          opts.separator ""
          opts.separator "Other options:"

          opts.on("-v", "--version", "Show version") do
            puts Fasti::VERSION
            throw :early_exit
          end

          opts.on("-h", "--help", "Show this help") do
            puts opts
            throw :early_exit
          end
        end
      end
    end

    # Parses config file arguments and returns option hash.
    #
    # @param args [Array<String>] Arguments from config file
    # @return [Hash] Parsed options
    private def parse_config_args(args)
      options = {}
      parser = create_option_parser(options, include_help: false)

      # Parse config file args
      parser.parse!(args.dup)
      options
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::InvalidArgument => e
      raise StandardError, "Invalid option in config file: #{e.message}"
    end

    # Generates and displays the calendar based on parsed options.
    #
    # @param options [Options] Parsed options
    private def generate_calendar(options)
      # Parse custom styles if provided
      custom_styles = {}
      if options.style
        style_parser = StyleParser.new
        custom_styles = style_parser.parse(options.style)
      end

      formatter = Formatter.new(custom_styles:)
      start_of_week = options.start_of_week

      output = case options.format
               when :month
                 generate_month_calendar(options, formatter, start_of_week)
               when :quarter
                 generate_quarter_calendar(options, formatter, start_of_week)
               when :year
                 generate_year_calendar(options, formatter, start_of_week)
               else
                 raise ArgumentError, "Unknown format: #{options.format}"
               end

      puts output
    end

    # Generates a single month calendar.
    #
    # @param options [Options] Parsed options
    # @param formatter [Formatter] Calendar formatter
    # @param start_of_week [Symbol] Week start preference
    # @return [String] Formatted calendar
    private def generate_month_calendar(options, formatter, start_of_week)
      calendar = Calendar.new(
        options.year,
        options.month,
        start_of_week:,
        country: options.country
      )
      formatter.format_month(calendar)
    end

    # Generates a quarter view calendar (3 months).
    #
    # @param options [Options] Parsed options
    # @param formatter [Formatter] Calendar formatter
    # @param start_of_week [Symbol] Week start preference
    # @return [String] Formatted quarter calendar
    private def generate_quarter_calendar(options, formatter, start_of_week)
      base_month = options.month
      year = options.year

      months = [(base_month - 1), base_month, (base_month + 1)].map {|m|
        if m < 1
          [year - 1, 12]
        elsif m > 12
          [year + 1, 1]
        else
          [year, m]
        end
      }

      calendars = months.map {|y, m|
        Calendar.new(y, m, start_of_week:, country: options.country)
      }

      formatter.format_quarter(calendars)
    end

    # Generates a full year calendar.
    #
    # @param options [Options] Parsed options
    # @param formatter [Formatter] Calendar formatter
    # @param start_of_week [Symbol] Week start preference
    # @return [String] Formatted year calendar
    private def generate_year_calendar(options, formatter, start_of_week)
      formatter.format_year(
        options.year,
        country: options.country,
        start_of_week:
      )
    end

    # Validates month parameter.
    #
    # @param month [Integer] Month to validate
    # @raise [ArgumentError] If month is invalid
    private def validate_month!(month)
      raise ArgumentError, "Month must be between 1 and 12" unless (1..12).include?(month)
    end

    # Validates year parameter.
    #
    # @param year [Integer] Year to validate
    # @raise [ArgumentError] If year is invalid
    private def validate_year!(year)
      raise ArgumentError, "Year must be positive" unless year.positive?
    end

    # Detects country code from environment variables (LC_ALL, LANG only).
    #
    # Uses LC_ALL and LANG only as they represent the user's preferred locale.
    # LC_MESSAGES and other LC_* variables are for specific categories and not
    # appropriate for determining holiday context.
    # Priority: LC_ALL > LANG
    #
    # @return [Symbol, nil] Country symbol (e.g., :jp, :us) or nil if not detected
    #
    # @example
    #   ENV["LC_ALL"] = "en_US.UTF-8"  # -> :us
    #   ENV["LANG"] = "ja_JP.UTF-8"    # -> :jp (if LC_ALL is unset)
    private def detect_country_from_environment
      env_vars = [ENV["LC_ALL"], ENV["LANG"]].compact.reject(&:empty?)

      env_vars.each do |var|
        # Skip C and POSIX locales as they don't represent specific countries
        next if %w[C POSIX].include?(var.upcase)

        begin
          locale_part = var.split(".").first
          parsed = Locale::Tag.parse(locale_part)
          return parsed.country.downcase.to_sym if parsed.country && !parsed.country.empty?
        rescue
          next
        end
      end

      nil
    end
  end
end
