# frozen_string_literal: true

require "bundler/gem_tasks"

# Load custom tasks
Dir.glob("lib/tasks/*.rake").each {|r| import r }

task default: %i[spec rubocop]
