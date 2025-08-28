# frozen_string_literal: true

require "paint"

module Fasti
  Style = Data.define(
    :foreground,
    :background,
    :inverse,
    :bold,
    :faint,
    :underline,
    :overline,
    :blink,
    :italic,
    :hide
  )

  # A style class that wraps Paint gem functionality for applying ANSI colors and text effects.
  #
  # This class provides an immutable way to define and compose terminal styling options.
  # It supports foreground/background colors, text decorations (bold, italic, underline, etc.),
  # and composition via the >> operator for layering styles.
  #
  # @example Basic usage
  #   style = Style.new(foreground: :red, bold: true)
  #   puts style.call("Hello")  # or style["Hello"] or style.("Hello")
  #
  # @example Style composition
  #   base = Style.new(foreground: :blue)
  #   emphasis = Style.new(bold: true, underline: true)
  #   combined = base >> emphasis
  #   puts combined.call("Styled text")  # or combined["Styled text"] or combined.("Styled text")
  #
  # @example Color and decoration options
  #   Style.new(
  #     foreground: :red,           # :default, :red, :green, :blue, etc. or hex "#FF0000"
  #     background: :yellow,        # same as foreground
  #     bold: true,                 # nil (unset), false (off), true (on)
  #     faint: false,               # mutually exclusive with bold
  #     underline: :double,         # nil, false, true, :double
  #     italic: true,               # nil, false, true
  #     inverse: true,              # nil, false, true
  #     # ... other boolean effects: overline, blink, hide
  #   )
  class Style
    # Initialize a new Style with the given attributes
    #
    # @param foreground [Symbol, String] Foreground color (:default, :red, :green, :blue, etc. or hex "#FF0000")
    # @param background [Symbol, String] Background color (same options as foreground)
    # @param inverse [nil, Boolean] Reverse foreground/background colors (nil=unset, false=off, true=on)
    # @param bold [nil, Boolean] Bold text (nil=unset, false=off, true=on, mutually exclusive with faint)
    # @param faint [nil, Boolean] Faint text (nil=unset, false=off, true=on, mutually exclusive with bold)
    # @param underline [nil, Boolean, Symbol] Underline (nil=unset, false=off, true=on, :double=double underline)
    # @param overline [nil, Boolean] Overline (nil=unset, false=off, true=on)
    # @param blink [nil, Boolean] Blinking text (nil=unset, false=off, true=on)
    # @param italic [nil, Boolean] Italic text (nil=unset, false=off, true=on)
    # @param hide [nil, Boolean] Hidden text (nil=unset, false=off, true=on)
    # @raise [ArgumentError] If both bold and faint are true, or if underline has invalid value
    def initialize(
      foreground: :default,
      background: :default,
      inverse: nil,
      bold: nil,
      faint: nil,
      underline: nil,
      overline: nil,
      blink: nil,
      italic: nil,
      hide: nil
    )
      # Handle bold/faint mutual exclusion
      if bold && faint
        raise ArgumentError, "Cannot specify both bold and faint simultaneously"
      end

      super
    end

    # Apply the style to the given text using Paint gem
    #
    # @param text [String] The text to apply styling to
    # @return [String] The styled text with ANSI escape codes, or plain text if no styles
    def call(text)
      styles = build_styles
      if styles.empty?
        text
      else
        Paint[text, *styles]
      end
    end

    alias [] call

    # Compose this style with another style, with the other style taking precedence
    # for explicitly set values. nil values in the other style preserve this style's values.
    #
    # @param other [Style] The style to compose with this one
    # @return [Style] A new Style instance with composed attributes
    # @example
    #   base = Style.new(foreground: :red, bold: true)
    #   overlay = Style.new(background: :blue, underline: true)
    #   result = base >> overlay  # red text, blue background, bold and underlined
    def >>(other)
      # Handle bold/faint mutual exclusion in composition
      composed_bold = other.bold.nil? ? bold : other.bold
      composed_faint = other.faint.nil? ? faint : other.faint

      # If other explicitly sets bold, clear faint; if other explicitly sets faint, clear bold
      if other.bold == true
        composed_faint = false
      elsif other.faint == true
        composed_bold = false
      end

      Style.new(
        foreground: other.foreground == :default ? foreground : other.foreground,
        background: other.background == :default ? background : other.background,
        inverse: other.inverse.nil? ? inverse : other.inverse,
        bold: composed_bold,
        faint: composed_faint,
        underline: other.underline.nil? ? underline : other.underline,
        overline: other.overline.nil? ? overline : other.overline,
        blink: other.blink.nil? ? blink : other.blink,
        italic: other.italic.nil? ? italic : other.italic,
        hide: other.hide.nil? ? hide : other.hide
      )
    end

    private def build_styles
      styles = []

      # Add colors individually
      if foreground != :default && background != :default
        styles << foreground
        styles << background
      elsif foreground != :default
        styles << foreground
      elsif background != :default
        styles << nil
        styles << background
      end

      # Add text decorations
      case underline
      when true
        styles << :underline
      when :double
        styles << :double_underline
      when nil, false
        # No underline
      else
        raise ArgumentError, "Invalid underline value: #{underline.inspect}"
      end

      styles << :overline if overline == true
      styles << :bold if bold == true
      styles << :faint if faint == true
      styles << :blink if blink == true
      styles << :italic if italic == true
      styles << :inverse if inverse == true
      styles << :hide if hide == true

      styles
    end
  end
end
