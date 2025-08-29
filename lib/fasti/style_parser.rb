# frozen_string_literal: true

module Fasti
  # Parses style definition strings into Style objects for calendar formatting.
  #
  # This class handles the parsing of style definition strings in the format:
  # "target:attribute=value,attribute,no-attribute target:attribute=value"
  #
  # Supported targets:
  # - Weekdays: sunday, monday, tuesday, wednesday, thursday, friday, saturday
  # - Special days: holiday, today
  #
  # Supported attributes:
  # - Colors: foreground=color, background=color
  # - Text effects: bold, italic, underline, underline=double, overline, blink, inverse, hide, faint
  # - Negation: no-bold, no-italic, etc.
  #
  # @example Basic usage
  #   parser = StyleParser.new
  #   styles = parser.parse("sunday:bold,foreground=red holiday:bold today:inverse")
  #   styles[:sunday] #=> Style.new(bold: true, foreground: :red)
  #
  # @example With negation
  #   styles = parser.parse("sunday:foreground=red,no-bold saturday:no-italic")
  #   styles[:sunday] #=> Style.new(foreground: :red, bold: false)
  class StyleParser
    # Valid target names that can be used in style definitions
    VALID_TARGETS = %w[sunday monday tuesday wednesday thursday friday saturday holiday today].freeze
    private_constant :VALID_TARGETS

    # Valid color names for foreground and background
    VALID_COLORS = %w[red green blue yellow magenta cyan white black default].freeze
    private_constant :VALID_COLORS

    # Valid boolean attributes that can be enabled/disabled
    BOOLEAN_ATTRIBUTES = %w[bold faint italic overline blink inverse hide].freeze
    private_constant :BOOLEAN_ATTRIBUTES

    # Special attributes that can have specific values
    SPECIAL_ATTRIBUTES = {"underline" => [true, false, :double]}.freeze
    private_constant :SPECIAL_ATTRIBUTES

    # Parses a style definition string into a hash of Style objects.
    #
    # @param style_string [String] Style definition string
    # @return [Hash<Symbol, Style>] Hash mapping target symbols to Style objects
    # @raise [ArgumentError] If the style string contains invalid syntax or values
    #
    # @example
    #   parse("sunday:bold,foreground=red holiday:bold today:inverse")
    #   #=> { sunday: Style.new(...), holiday: Style.new(...), today: Style.new(...) }
    def parse(style_string)
      return {} if style_string.nil? || style_string.strip.empty?

      style_string.strip.split(/\s+/).each_with_object({}) do |entry, styles|
        target, attributes_hash = parse_entry(entry)
        styles[target] = create_style(attributes_hash)
      end
    end

    # Parses a single style entry in the format "target:attributes"
    #
    # @param entry [String] Single style entry
    # @return [Array<Symbol, Hash>] Target symbol and attributes hash
    # @raise [ArgumentError] If entry format is invalid
    private def parse_entry(entry)
      parts = entry.split(":", 2)
      raise ArgumentError, "Invalid style entry format: '#{entry}'" if parts.length != 2

      target = parts[0].strip
      attributes_str = parts[1].strip

      raise ArgumentError, "Invalid target: '#{target}'" unless VALID_TARGETS.include?(target)

      attributes = parse_attributes(attributes_str)
      [target.to_sym, attributes]
    end

    # Parses attribute string into a hash of attribute names and values
    #
    # @param attributes_str [String] Comma-separated attribute string
    # @return [Hash<String, Object>] Hash of attribute names to values
    private def parse_attributes(attributes_str)
      attributes = {}

      attributes_str.split(",").each do |attr|
        attr = attr.strip
        next if attr.empty?

        case attr
        when /\Ano-(.+)\z/
          # Handle no- prefix (negation)
          attribute_name = $1
          validate_boolean_attribute(attribute_name)
          attributes[attribute_name] = false
        when /\A(.+)=(.+)\z/
          # Handle key=value format
          key = $1.strip
          value = $2.strip
          attributes[key] = parse_attribute_value(key, value)
        else
          # Handle simple boolean attributes (bold, italic, etc.)
          validate_boolean_attribute(attr)
          attributes[attr] = true
        end
      end

      attributes
    end

    # Parses an attribute value based on the attribute key
    #
    # @param key [String] Attribute name
    # @param value [String] Attribute value
    # @return [Object] Parsed value (Symbol, Boolean, etc.)
    # @raise [ArgumentError] If the key or value is invalid
    private def parse_attribute_value(key, value)
      case key
      when "foreground", "background"
        parse_color_value(value)
      when "underline"
        parse_underline_value(value)
      when *BOOLEAN_ATTRIBUTES
        raise ArgumentError, "Boolean attributes should not use '=' syntax. Use '#{key}' or 'no-#{key}' instead"
      else
        raise ArgumentError, "Unknown attribute: '#{key}'"
      end
    end

    # Parses a color value (color name or hex code)
    #
    # @param value [String] Color value
    # @return [Symbol, String] Color as symbol or hex string
    # @raise [ArgumentError] If color is invalid
    private def parse_color_value(value)
      # Check if it's a hex color (with or without #)
      if value.match?(/\A#?\h{3}(?:\h{3})?\z/)
        parse_hex_color(value)
      elsif VALID_COLORS.include?(value)
        value.to_sym
      else
        raise ArgumentError, "Invalid color: '#{value}'. Valid colors: #{VALID_COLORS.join(", ")}, or hex colors " \
                             "(#RGB, #RRGGBB, RGB, RRGGBB)"
      end
    end

    # Parses and normalizes hex color values
    #
    # @param value [String] Hex color value (with or without #, 3 or 6 digits)
    # @return [String] Normalized 6-digit hex color with #
    # @raise [ArgumentError] If hex color format is invalid
    private def parse_hex_color(value)
      # Remove # if present
      hex_part = value.start_with?("#") ? value[1..] : value

      case hex_part.length
      when 3
        # Expand 3-digit to 6-digit (F00 -> FF0000)
        expanded = hex_part.chars.map {|c| c + c }.join
        "##{expanded.upcase}"
      when 6
        "##{hex_part.upcase}"
      else
        raise ArgumentError, "Invalid hex color: '#{value}'. Use 3-digit (#RGB) or 6-digit (#RRGGBB) format"
      end
    end

    # Parses underline attribute value
    #
    # @param value [String] Underline value
    # @return [Symbol] Parsed underline value
    # @raise [ArgumentError] If underline value is invalid
    private def parse_underline_value(value)
      case value
      when "double"
        :double
      else
        raise ArgumentError, "Invalid underline value: '#{value}'. Valid values: double"
      end
    end

    # Validates that an attribute is a valid boolean attribute
    #
    # @param attribute [String] Attribute name to validate
    # @raise [ArgumentError] If attribute is not a valid boolean attribute
    private def validate_boolean_attribute(attribute)
      valid_attributes = BOOLEAN_ATTRIBUTES + ["underline"]
      return if valid_attributes.include?(attribute)

      raise ArgumentError,
        "Invalid boolean attribute: '#{attribute}'. Valid attributes: #{valid_attributes.join(", ")}"
    end

    # Creates a Style object from parsed attributes
    #
    # @param attributes [Hash<String, Object>] Hash of attribute names to values
    # @return [Style] New Style object
    private def create_style(attributes)
      style_params = attributes.transform_keys(&:to_sym)

      Style.new(**style_params)
    end
  end
end
