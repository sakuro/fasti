# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# Load custom tasks
Dir.glob("lib/tasks/*.rake").each {|r| import r }

task default: %i[spec rubocop]
