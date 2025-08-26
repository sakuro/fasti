# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in fasti.gemspec
gemspec

group :development do
  gem "rubocop", "~> 1.21" # Ruby static code analyzer and formatter
  gem "rubocop-rake" # RuboCop plugin for Rake tasks
  gem "rubocop-rspec" # RuboCop plugin for RSpec
end

group :test do
  gem "rspec", "~> 3.0" # Testing framework
  gem "tty-command", "~> 0.10" # Command execution for CLI testing
end

group :development, :test do
  gem "irb" # Interactive Ruby shell for development and test debugging (binding.irb)
  gem "rake", "~> 13.0" # Build automation tool
  gem "repl_type_completor", "~> 0.1.11" # Enhanced REPL type completion
end
