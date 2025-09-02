# frozen_string_literal: true

require "dry-schema"
require_relative "config_types"

module Fasti
  # Configuration schema definitions using dry-schema
  #
  # Provides structured validation for configuration hashes.
  module ConfigSchema
    # Style attribute schema
    # Defines the structure for individual style attributes like {bold: true, foreground: :red}
    StyleAttributeSchema = Dry::Schema.Params {
      config.validate_keys = true # Strict mode: reject unknown keys

      # Color attributes
      optional(:foreground).maybe(ConfigTypes::Color)
      optional(:background).maybe(ConfigTypes::Color)

      # Boolean styling attributes
      optional(:bold).maybe(ConfigTypes::BooleanAttribute)
      optional(:italic).maybe(ConfigTypes::BooleanAttribute)
      optional(:faint).maybe(ConfigTypes::BooleanAttribute)
      optional(:inverse).maybe(ConfigTypes::BooleanAttribute)
      optional(:blink).maybe(ConfigTypes::BooleanAttribute)
      optional(:hide).maybe(ConfigTypes::BooleanAttribute)
      optional(:overline).maybe(ConfigTypes::BooleanAttribute)

      # Special underline attribute
      optional(:underline).maybe(ConfigTypes::UnderlineValue)
    }

    public_constant :StyleAttributeSchema
  end
end
