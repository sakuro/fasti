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
        optional(:bold).maybe(Types::Params::Bool)
        optional(:italic).maybe(Types::Params::Bool)
        optional(:faint).maybe(Types::Params::Bool)
        optional(:inverse).maybe(Types::Params::Bool)
        optional(:blink).maybe(Types::Params::Bool)
        optional(:hide).maybe(Types::Params::Bool)
        optional(:overline).maybe(Types::Params::Bool)

        # Special underline attribute
        optional(:underline).maybe(Types::Underline)
      }

      public_constant :StyleAttribute
    end
  end
end
