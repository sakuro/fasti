# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/clean"
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

# Clean and clobber tasks
CLEAN.include("coverage/", ".rspec_status", ".yardoc")
CLOBBER.include("docs/api/", "pkg/")

# Load custom tasks
Dir.glob("lib/tasks/*.rake").each {|r| import r }

task default: %i[spec rubocop]
