# frozen_string_literal: true

# Fasti Configuration Example
# This file shows how to configure fasti using dry-configurable
# Place this file at ~/.config/fasti/config.rb (or other XDG-compliant location)

Fasti.configure do |config|
  # Basic calendar format and appearance
  config.format = :month # :month, :quarter, :year
  config.start_of_week = :monday # :sunday, :monday, etc.
  config.country = :jp # ISO country code for holidays

  # Style configuration using structured hash format
  # This is much cleaner and more maintainable than string-based definitions
  config.style = {
    # Weekday styles
    sunday: {
      foreground: :red,
      bold: true
    },

    monday: {
      foreground: :blue
    },

    saturday: {
      foreground: :cyan,
      bold: true
    },

    # Special day styles
    holiday: {
      foreground: :red,
      background: :yellow,
      bold: true,
      inverse: true
    },

    today: {
      background: :green,
      bold: true,
      underline: :double
    }
  }
end

# Examples of different style attribute combinations:
#
# Color attributes:
# - foreground: :red, :blue, :green, :yellow, :magenta, :cyan, :white, :black, :default
# - foreground: "#FF0000", "#00FF00", "#0000FF" (hex colors)
# - background: (same options as foreground)
#
# Boolean attributes:
# - bold: true/false
# - italic: true/false
# - faint: true/false
# - inverse: true/false
# - blink: true/false
# - hide: true/false
# - overline: true/false
#
# Special attributes:
# - underline: true/false/:double

# Alternative: Default-like minimal styling
# Fasti.configure do |config|
#   config.format = :month
#   config.style = {
#     sunday: { bold: true },
#     holiday: { bold: true },
#     today: { inverse: true }
#   }
# end

# Alternative: No styling (plain text)
# Fasti.configure do |config|
#   config.format = :quarter
#   config.country = :us
#   # style defaults to nil (no custom styling)
# end
