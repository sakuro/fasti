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
        optional(:bold).maybe(Types::MaybeBool)
        optional(:italic).maybe(Types::MaybeBool)
        optional(:faint).maybe(Types::MaybeBool)
        optional(:inverse).maybe(Types::MaybeBool)
        optional(:blink).maybe(Types::MaybeBool)
        optional(:hide).maybe(Types::MaybeBool)
        optional(:overline).maybe(Types::MaybeBool)

        # Special underline attribute
        optional(:underline).maybe(Types::Underline)
      }

      public_constant :StyleAttribute
    end
  end
end
