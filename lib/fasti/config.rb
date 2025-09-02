# frozen_string_literal: true

require "dry-configurable"
require_relative "config/schema"
require_relative "config/types"
require_relative "style"

# Fasti configuration management components
module Fasti
  # Configuration management using dry-configurable
  #
  # Provides a clean interface for managing fasti configuration
  # with type safety and validation.
  #
  # @example Basic usage
  #   Fasti.configure do |config|
  #     config.format = :quarter
  #     config.country = :jp
  #   end
  #
  # @example With styling
  #   Fasti.configure do |config|
  #     config.style = {
  #       sunday: { foreground: :red, bold: true },
  #       holiday: { background: :yellow }
  #     }
  #   end
  class Config
    extend Dry::Configurable

    # Calendar display format
    setting :format, default: :month, constructor: Types::Format

    # Week start day
    setting :start_of_week, default: :sunday, constructor: Types::StartOfWeek

    # Country code for holiday detection
    setting :country, default: :us, constructor: Types::Country

    # Style configuration
    # Accepts a hash mapping style targets to their attributes
    # @param value [Hash<Symbol|String, Hash>] Style configuration hash
    # @return [Hash<Symbol, Hash>] Validated and normalized style hash
    setting :style, default: nil, constructor: ->(value) do
      case value
      when nil
        nil
      when Hash
        validate_and_normalize_style(value)
      else
        raise ArgumentError, "Style must be nil or Hash, got #{value.class}"
      end
    end

    # Validates and normalizes a style configuration hash
    #
    # @param style_hash [Hash] Raw style configuration
    # @return [Hash<Symbol, Hash>] Validated and normalized style hash
    # @raise [ArgumentError] If validation fails
    def self.validate_and_normalize_style(style_hash)
      validated_style = {}

      style_hash.each do |target, attributes|
        # Validate and convert target
        target_sym = Types::StyleTarget.call(target)

        # Validate attributes structure
        unless attributes.is_a?(Hash)
          raise ArgumentError, "Style attributes for #{target} must be a Hash, got #{attributes.class}"
        end

        # Validate individual attributes using schema
        result = Schema::StyleAttribute.call(attributes)
        if result.success?
          validated_style[target_sym] = Style.new(**result.to_h)
        else
          errors = result.errors.to_h.map {|key, messages|
            "#{key}: #{Array(messages).join(", ")}"
          }.join("; ")
          raise ArgumentError, "Invalid style attributes for #{target}: #{errors}"
        end
      end

      validated_style
    end

    # Reset configuration to defaults
    def self.reset!
      configure do |config|
        config.format = :month
        config.start_of_week = :sunday
        config.country = :us
        config.style = nil
      end
    end

    # Load configuration from a Ruby file
    #
    # @param file_path [String] Path to configuration file
    # @return [Hash] Configuration hash loaded from file
    # @raise [ConfigError] If file has syntax errors
    def self.load_from_file(file_path)
      return {} unless File.exist?(file_path)

      begin
        # Execute the configuration file in the context of Fasti
        instance_eval(File.read(file_path), file_path)
        config.to_h
      rescue SyntaxError => e
        raise ConfigError, "Invalid Ruby syntax in #{file_path}: #{e.message}"
      rescue => e
        raise ConfigError, "Error loading configuration from #{file_path}: #{e.message}"
      end
    end
  end

  # Configuration error
  class ConfigError < StandardError; end

  # Convenience method for configuration
  def self.configure(&)
    Config.configure(&)
  end

  # Access current configuration
  def self.config
    Config.config
  end
end
