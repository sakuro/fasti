# frozen_string_literal: true

require "tint_me"
require "zeitwerk"

# Manually require version for gemspec compatibility (ignored by Zeitwerk)
require_relative "fasti/version"

# Fasti - Flexible calendar application with multi-country holiday support
#
# Main namespace containing all Fasti components including configuration,
# calendar logic, formatting, and CLI interface.
module Fasti
  # Setup Zeitwerk autoloader
  loader = Zeitwerk::Loader.for_gem
  # VERSION constant doesn't follow Zeitwerk naming conventions, so ignore it
  loader.ignore("#{__dir__}/fasti/version.rb")
  # CLI acronym inflection - cli.rb defines CLI constant, not Cli
  loader.inflector.inflect("cli" => "CLI")
  loader.setup
end
