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

      # Color values (named colors only for now, hex colors can be added later)
      Color = Coercible::Symbol.constrained(
        included_in: %i[red blue green yellow magenta cyan white black default]
      )

      # Underline attribute value (true | false | :double)
      Underline = Params::Bool | Coercible::Symbol.constrained(included_in: [:double])

      # Boolean attributes with coercion (true | false | nil)
      MaybeBool = Params::Bool

      # Make all type constants explicitly public
      public_constant :Format
      public_constant :StartOfWeek
      public_constant :Country
      public_constant :StyleTarget
      public_constant :Color
      public_constant :Underline
      public_constant :MaybeBool
    end
  end
end
