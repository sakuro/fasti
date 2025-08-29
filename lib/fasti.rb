# frozen_string_literal: true

require_relative "fasti/calendar"
require_relative "fasti/cli"
require_relative "fasti/formatter"
require_relative "fasti/style"
require_relative "fasti/style_parser"
require_relative "fasti/version"

module Fasti
  class Error < StandardError; end
end
