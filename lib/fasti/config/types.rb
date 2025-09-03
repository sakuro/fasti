# frozen_string_literal: true

require "dry-types"

module Fasti
  class Config
    # Configuration types using dry-types
    #
    # Provides type definitions for configuration values with automatic
    # coercion and validation.
    module Types
      include Dry.Types()

      # Calendar display format
      Format = Coercible::Symbol.constrained(
        included_in: %i[month quarter year]
      )

      # Week start day
      StartOfWeek = Coercible::Symbol.constrained(
        included_in: %i[sunday monday tuesday wednesday thursday friday saturday]
      )

      # Country code for holiday detection
      Country = Coercible::Symbol

      # Style target names
      StyleTarget = Coercible::Symbol.constrained(
        included_in: %i[sunday monday tuesday wednesday thursday friday saturday holiday today]
      )

      # Named color values
      NamedColor = Coercible::Symbol.constrained(
        included_in: %i[red blue green yellow magenta cyan white black default]
      )

      # Hex color values (e.g., "#FF0000", "#F00", "FF0000", "F00")
      HexColor = Coercible::String.constrained(format: /\A#?\h{3}(?:\h{3})?\z/)

      # Color values (named colors or hex colors)
      Color = NamedColor | HexColor

      # Underline attribute value (true | false | :double)
      Underline = Params::Bool | Coercible::Symbol.constrained(included_in: [:double])

      # Internal type constants (used only for composition)
      private_constant :NamedColor
      private_constant :HexColor

      # Make public type constants explicitly public
      public_constant :Format
      public_constant :StartOfWeek
      public_constant :Country
      public_constant :StyleTarget
      public_constant :Color
      public_constant :Underline
    end
  end
end
