# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# Documentation task
begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files = ["lib/**/*.rb", "exe/fasti"]
    t.options = ["--output-dir", "docs/api", "--markup", "markdown"]
  end
rescue LoadError
  # YARD not available
end

# Load custom tasks
Dir.glob("lib/tasks/*.rake").each {|r| import r }

task default: %i[spec rubocop]
