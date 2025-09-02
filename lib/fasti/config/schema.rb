# frozen_string_literal: true

require "dry-schema"
require_relative "types"

module Fasti
  class Config
    # Configuration schema definitions using dry-schema
    #
    # Provides structured validation for configuration hashes.
    module Schema
      # Style attribute schema
      # Defines the structure for individual style attributes like {bold: true, foreground: :red}
      StyleAttribute = Dry::Schema.Params {
        config.validate_keys = true # Strict mode: reject unknown keys

        # Color attributes
        optional(:foreground).maybe(Types::Color)
        optional(:background).maybe(Types::Color)

        # Boolean styling attributes
        optional(:bold).maybe(Types::BooleanAttribute)
        optional(:italic).maybe(Types::BooleanAttribute)
        optional(:faint).maybe(Types::BooleanAttribute)
        optional(:inverse).maybe(Types::BooleanAttribute)
        optional(:blink).maybe(Types::BooleanAttribute)
        optional(:hide).maybe(Types::BooleanAttribute)
        optional(:overline).maybe(Types::BooleanAttribute)

        # Special underline attribute
        optional(:underline).maybe(Types::UnderlineValue)
      }

      public_constant :StyleAttribute
    end
  end
end
