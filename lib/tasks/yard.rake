# frozen_string_literal: true

require "yard"

# Documentation task
YARD::Rake::YardocTask.new(:doc) do |t|
  t.files = ["lib/**/*.rb", "exe/fasti"]
  t.options = ["--output-dir", "docs/api", "--markup", "markdown"]
end
