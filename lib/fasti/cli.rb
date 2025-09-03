# frozen_string_literal: true

require "locale"
require "optparse"
require "pathname"

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
  # - Path: `$XDG_CONFIG_HOME/fasti/config.rb` (or `$HOME/.config/fasti/config.rb` if XDG_CONFIG_HOME is unset)
  # - Format: Ruby DSL using Fasti.configure block
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
  # @example Config file content ($HOME/.config/fasti/config.rb)
  #   Fasti.configure do |config|
  #     config.format = :quarter
  #     config.start_of_week = :monday
  #     config.country = :US
  #   end
  class CLI
    # Non-country locales that should be skipped in country detection
    NON_COUNTRY_LOCALES = %w[C POSIX].freeze
    private_constant :NON_COUNTRY_LOCALES

    # General configuration attributes (non-style attributes)
    GENERAL_ATTRIBUTES = %i[format start_of_week country].freeze
    private_constant :GENERAL_ATTRIBUTES

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
      @current_time = Time.now # Single source of truth for time
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
      # 1. Get base options from config file + defaults
      base_options = default_options

      # 2. Parse CLI arguments into separate hash
      cli_options_hash = {}
      parser = create_option_parser(cli_options_hash, include_help: true)
      parser.parse!(argv) # Destructively modifies argv

      # 3. Parse remaining positional arguments
      month, year = parse_positional_args(argv)

      # 4. Apply CLI option overrides to base options
      final_options = apply_cli_overrides(base_options, cli_options_hash)

      # 5. Validate required options
      unless final_options.country
        raise ArgumentError,
          "Country could not be determined. Use --country with a country code or set LANG/LC_ALL environment variables"
      end

      [month, year, final_options]
    end

    # Returns base option values (defaults merged with config file settings).
    #
    # @return [Options] Base options for further CLI option composition
    private def default_options
      defaults = base_default_values
      config_options = load_config_options
      merge_defaults_with_config(defaults, config_options)
    end

    # Returns the base default option values.
    #
    # @return [Hash] Base default values
    private def base_default_values
      {
        format: :month,
        start_of_week: :sunday,
        country: detect_country_from_environment,
        style: nil
      }
    end

    # Merges default values with config file options.
    #
    # @param defaults [Hash] Base default values
    # @param config_options [Hash] Config file options
    # @return [Options] Merged options object
    private def merge_defaults_with_config(defaults, config_options)
      # Merge general attributes (config overrides defaults)
      merged_general = defaults.slice(*GENERAL_ATTRIBUTES)
        .merge(config_options.slice(*GENERAL_ATTRIBUTES))

      # Handle style separately (just use config style, no defaults)
      merged_options = merged_general.merge(style: config_options[:style])

      Options.new(**merged_options)
    end

    # Loads options from the config file if it exists.
    #
    # @return [Hash] Config options or empty hash if no config file
    private def load_config_options
      config_file = config_file_path
      return {} unless config_file.exist?

      begin
        Config.load_from_file(config_file.to_s)
      rescue => e
        puts "Warning: Failed to load config file #{config_file}: #{e.message}"
        {}
      end
    end

    # Determines the config file path using XDG specification.
    #
    # @return [Pathname] Path to config file
    private def config_file_path
      config_home = ENV["XDG_CONFIG_HOME"] || (Pathname.new(Dir.home) / ".config")
      Pathname.new(config_home) / "fasti" / "config.rb"
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
          # Parse style string immediately to Hash format
          options[:style] = StyleParser.new.parse(style)
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

    # Generates and displays the calendar based on parsed options.
    #
    # @param options [Options] Parsed options
    private def generate_calendar(month, year, options)
      styles = options.style || {}

      formatter = Formatter.new(styles:)
      start_of_week = options.start_of_week
      country = options.country

      output = case options.format
               when :month
                 generate_month_calendar(month, year, country, formatter, start_of_week)
               when :quarter
                 generate_quarter_calendar(month, year, country, formatter, start_of_week)
               when :year
                 generate_year_calendar(month, year, country, formatter, start_of_week)
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
    private def generate_month_calendar(month, year, country, formatter, start_of_week)
      calendar = Calendar.new(
        year,
        month,
        start_of_week:,
        country:
      )
      formatter.format_month(calendar)
    end

    # Generates a quarter view calendar (3 months).
    #
    # @param options [Options] Parsed options
    # @param formatter [Formatter] Calendar formatter
    # @param start_of_week [Symbol] Week start preference
    # @return [String] Formatted quarter calendar
    private def generate_quarter_calendar(month, year, country, formatter, start_of_week)
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
        Calendar.new(y, m, start_of_week:, country:)
      }

      formatter.format_quarter(calendars)
    end

    # Generates a full year calendar.
    #
    # @param options [Options] Parsed options
    # @param formatter [Formatter] Calendar formatter
    # @param start_of_week [Symbol] Week start preference
    # @return [String] Formatted year calendar
    private def generate_year_calendar(_month, year, country, formatter, start_of_week)
      formatter.format_year(
        year,
        country:,
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
        # Use current month and year from instance variable
        [@current_time.month, @current_time.year]
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
        [value, @current_time.year] # Return [month, current_year]
      elsif value >= 13
        [@current_time.month, value] # Return [current_month, year]
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

    # Applies CLI option overrides to base options, handling style composition specially.
    #
    # @param base_options [Options] Base options (config + defaults)
    # @param cli_overrides [Hash] CLI option overrides
    # @return [Options] Final options with CLI overrides applied
    private def apply_cli_overrides(base_options, cli_overrides)
      # Merge general attributes (CLI overrides base)
      merged_general = base_options.to_h.slice(*GENERAL_ATTRIBUTES)
        .merge(cli_overrides.slice(*GENERAL_ATTRIBUTES))

      # Compose styles specially (not simple override)
      merged_style = compose_styles(base_options.style, cli_overrides[:style])

      # Create final options
      Options.new(**merged_general, style: merged_style)
    end

    # Composes two style hashes using Style >> operator for same targets
    #
    # @param base_styles [Hash<Symbol, Style>, nil] Base style hash
    # @param overlay_styles [Hash<Symbol, Style>, nil] Overlay style hash
    # @return [Hash<Symbol, Style>] Composed style hash
    private def compose_styles(base_styles, overlay_styles)
      return overlay_styles if base_styles.nil?
      return base_styles if overlay_styles.nil?

      result = base_styles.dup
      overlay_styles.each do |target, overlay_style|
        result[target] = if result[target]
                           # Same target: compose using >> operator
                           result[target] >> overlay_style
                         else
                           # New target: add directly
                           overlay_style
                         end
      end

      result
    end
  end
end
