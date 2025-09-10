# frozen_string_literal: true

class ContainStyled
  # ANSI numeric codes for Style class attributes and test usage
  ANSI_NUMERIC_CODES = {
    # Text attributes (from Style class)
    reset: 0,
    bold: 1,
    faint: 2,
    italic: 3,
    underline: 4,
    blink: 5,
    inverse: 7,
    conceal: 8,
    overline: 53,
    double_underline: 21,

    # Foreground colors (used in tests and Style)
    black: 30,
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37,

    # Background colors (used in tests and Style)
    black_bg: 40,
    red_bg: 41,
    green_bg: 42,
    yellow_bg: 43,
    blue_bg: 44,
    magenta_bg: 45,
    cyan_bg: 46,
    white_bg: 47
  }.freeze

  private_constant :ANSI_NUMERIC_CODES

  def initialize(*args, reset: true)
    @content = args.pop
    @styles = args.flatten
    @reset = reset
  end

  # Generate ANSI escape sequence from multiple style symbols
  def ansi_sequence(*styles)
    raise ArgumentError, "At least one style must be provided" if styles.empty?

    # Validate all styles exist
    invalid_styles = styles.reject {|style| ANSI_NUMERIC_CODES.key?(style) }
    unless invalid_styles.empty?
      raise ArgumentError, "Unknown styles: #{invalid_styles.join(", ")}"
    end

    codes = styles.map {|style| ANSI_NUMERIC_CODES[style] }

    "\e[#{codes.join(";")}m"
  end

  def matches?(actual)
    @actual = actual
    ansi_code = ansi_sequence(*@styles)
    reset_code = @reset ? "\e[0m" : ""

    if @content.is_a?(Regexp)
      pattern_string = "#{Regexp.escape(ansi_code)}#{@content.source}#{Regexp.escape(reset_code)}"
      pattern = Regexp.new(pattern_string)
      actual.match?(pattern)
    else
      actual.include?("#{ansi_code}#{@content}#{reset_code}")
    end
  end

  def failure_message
    ansi_code = ansi_sequence(*@styles)
    reset_code = @reset ? "\e[0m" : ""

    if @content.is_a?(Regexp)
      expected_pattern = "#{ansi_code}#{@content.source}#{reset_code}"
      actual_pattern = Regexp.new("#{Regexp.escape(ansi_code)}#{@content.source}#{Regexp.escape(reset_code)}")
    else
      expected_pattern = "#{ansi_code}#{@content}#{reset_code}"
      actual_pattern = expected_pattern
    end

    message_type = @reset ? "ANSI styled text" : "style start"
    "expected #{@actual.inspect} to contain #{message_type} matching: #{expected_pattern.inspect}\\nActual search pattern: #{actual_pattern.inspect}"
  end

  def failure_message_when_negated
    ansi_code = ansi_sequence(*@styles)
    reset_code = @reset ? "\e[0m" : ""
    expected_pattern = "#{ansi_code}#{@content}#{reset_code}"

    message_type = @reset ? "ANSI styled text" : "style start"
    "expected #{@actual.inspect} not to contain #{message_type}: #{expected_pattern.inspect}"
  end

  def description
    style_description = @styles.join("+")
    "contain #{style_description}-styled content #{@content.inspect}"
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def contain_styled(*, **)
      ContainStyled.new(*, **)
    end
  end)
end
