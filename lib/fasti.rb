# frozen_string_literal: true

require "tint_me"
require_relative "fasti/calendar"
require_relative "fasti/cli"
require_relative "fasti/config"
require_relative "fasti/formatter"
require_relative "fasti/style_parser"
require_relative "fasti/version"

# Fasti - Flexible calendar application with multi-country holiday support
#
# Main namespace containing all Fasti components including configuration,
# calendar logic, formatting, and CLI interface.
module Fasti
  class Error < StandardError; end
end
