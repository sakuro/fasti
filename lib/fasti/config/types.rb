# frozen_string_literal: true

require "dry-types"
require "tint_me"

module Fasti
  class Config
    # Configuration types using dry-types and TIntMe types
    #
    # Provides type definitions for configuration values with automatic
    # coercion and validation. Style-related types are inherited from
    # TIntMe for consistency and enhanced functionality.
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

      # Color values - TIntMe's type with smart coercion
      # Named colors: string -> symbol, hex colors: preserved as string
      # Extract color names directly from TIntMe to ensure consistency
      # TIntMe::Style::Types::Color = SymbolEnum | HexString, we need the left (Symbol) side
      TINTME_COLOR_NAMES = TIntMe::Style::Types::Color.left.values.freeze
      NamedColorCoercion = Coercible::Symbol.constrained(included_in: TINTME_COLOR_NAMES)
      HexColorString = Coercible::String.constrained(format: /\A#?\h{3}(?:\h{3})?\z/)
      Color = NamedColorCoercion | HexColorString

      # Underline attribute value - compatible with TIntMe with coercion
      # Extract special values from TIntMe UnderlineOption type
      # TIntMe::Style::Types::UnderlineOption = Nil | True | False | Enum[:double, :reset]
      # Navigate: UnderlineOption.right.right to get the Enum part
      TINTME_UNDERLINE_SYMBOLS = TIntMe::Style::Types::UnderlineOption.right.right.values.freeze
      UnderlineOption = Params::Bool.optional |
                        Coercible::Symbol.constrained(included_in: TINTME_UNDERLINE_SYMBOLS)

      # Internal type constants (used only for composition)
      private_constant :TINTME_COLOR_NAMES
      private_constant :TINTME_UNDERLINE_SYMBOLS
      private_constant :NamedColorCoercion
      private_constant :HexColorString

      # Make public type constants explicitly public
      public_constant :Format
      public_constant :StartOfWeek
      public_constant :Country
      public_constant :StyleTarget
      public_constant :Color
      public_constant :UnderlineOption
    end
  end
end
