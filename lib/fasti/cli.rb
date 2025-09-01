# frozen_string_literal: true

require "locale"
require "optparse"
require "pathname"
require "shellwords"

module Fasti
  # Immutable data structure for CLI options
  Options = Data.define(:format, :start_of_week, :country, :style)

  # Command-line interface for the fasti calendar application.
  #
  # This class handles all CLI functionality including option parsing, validation,
  # and calendar generation. It supports various display formats and customization
  # options while maintaining backwards compatibility.
  #
  # ## Usage
  # Positional arguments for month/year specification:
  # - 0 args: current month + current year
  # - 1 arg: 1-12 → month + current year, 13+ → current month + year
  # - 2 args: month year (first arg = month 1-12, second arg = year)
  #
  # ## Options
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
  #   CLI.run(["6", "2024"])  # June 2024
  #
  # @example Month only
  #   CLI.run(["6"])  # June current year
  #
  # @example Year only
  #   CLI.run(["2024"])  # Current month 2024
  #
  # @example Year view
  #   CLI.run(["2024", "--format", "year", "--country", "US"])
  #
  # @example Config file content ($HOME/.config/fastirc)
  #   --format quarter --start-of-week monday --country US
  class CLI
    # Non-country locales that should be skipped in country detection
    NON_COUNTRY_LOCALES = %w[C POSIX].freeze
    private_constant :NON_COUNTRY_LOCALES

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
        month, year, options = parse_options(argv)
        generate_calendar(month, year, options)
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
      options_hash = default_options.to_h

      # 1. Parse options first - removes them from argv automatically
      parser = create_option_parser(options_hash, include_help: true)
      parser.parse!(argv) # Destructively modifies argv

      # 2. Parse remaining positional arguments
      month, year = parse_positional_args(argv)

      # 3. Create options and return with month/year
      options = Options.new(**options_hash)

      # Validate required options
      unless options.country
        raise ArgumentError,
          "Country could not be determined. Use --country with a country code or set LANG/LC_ALL environment variables"
      end

      [month, year, options]
    end

    # Returns default option values merged with config file settings.
    #
    # @return [Options] Default options
    private def default_options
      defaults = {
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
        opts.accept(:downcase_symbol) {|value| value.downcase.to_sym }
        if include_help
          opts.banner = "Usage: fasti [month] [year] [options]"
          opts.separator ""
          opts.separator "Arguments:"
          opts.separator "  month  Month (1-12, optional)"
          opts.separator "  year   Year (optional)"
          opts.separator ""
          opts.separator "Calendar display options:"
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
    private def generate_calendar(month, year, options)
      # Parse custom styles if provided
      styles = options.style ? StyleParser.new.parse(options.style) : {}

      formatter = Formatter.new(styles:)
      start_of_week = options.start_of_week

      output = case options.format
               when :month
                 generate_month_calendar(month, year, options, formatter, start_of_week)
               when :quarter
                 generate_quarter_calendar(month, year, options, formatter, start_of_week)
               when :year
                 generate_year_calendar(month, year, options, formatter, start_of_week)
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
    private def generate_month_calendar(month, year, options, formatter, start_of_week)
      calendar = Calendar.new(
        year,
        month,
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
    private def generate_quarter_calendar(month, year, options, formatter, start_of_week)
      base_month = month

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
    private def generate_year_calendar(_month, year, options, formatter, start_of_week)
      formatter.format_year(
        year,
        country: options.country,
        start_of_week:
      )
    end

    # Validates month parameter.
    #
    # @param month [Integer] Month to validate
    # @raise [ArgumentError] If month is invalid
    private def validate_month!(month)
      raise ArgumentError, "Month must be between 1 and 12" unless (1..12).cover?(month)
    end

    # Validates year parameter.
    #
    # @param year [Integer] Year to validate
    # @raise [ArgumentError] If year is invalid
    private def validate_year!(year)
      raise ArgumentError, "Year must be positive" unless year.positive?
    end

    # Parse positional arguments for month and year specification
    private def parse_positional_args(argv)
      case argv.length
      when 0
        # Use current month and year
        [Time.now.month, Time.now.year]
      when 1
        interpret_single_argument(argv[0])
      when 2
        validate_two_arguments(argv[0], argv[1])
      else
        raise ArgumentError, "Too many arguments. Expected 0-2, got #{argv.length}"
      end
    end

    # Single argument interpretation
    private def interpret_single_argument(arg)
      begin
        value = Integer(arg, 10)
      rescue ArgumentError
        raise ArgumentError, "Invalid argument: '#{arg}'. Expected integer."
      end

      if (1..12).cover?(value)
        [value, Time.now.year] # Return [month, current_year]
      elsif value >= 13
        [Time.now.month, value] # Return [current_month, year]
      else
        raise ArgumentError, "Invalid argument: #{value}. Expected 1-12 (month) or 13+ (year)."
      end
    end

    # Two argument validation
    private def validate_two_arguments(month_arg, year_arg)
      begin
        month = Integer(month_arg, 10)
      rescue ArgumentError
        raise ArgumentError, "Invalid month: '#{month_arg}'"
      end

      begin
        year = Integer(year_arg, 10)
      rescue ArgumentError
        raise ArgumentError, "Invalid year: '#{year_arg}'"
      end

      validate_month!(month)
      validate_year!(year)

      [month, year] # Return [month, year]
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
      env_vars = [ENV["LC_ALL"], ENV["LANG"]]
      env_vars.compact!
      env_vars.reject!(&:empty?)

      env_vars.each do |var|
        # Skip C and POSIX locales as they don't represent specific countries
        next if NON_COUNTRY_LOCALES.include?(var.upcase)

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
