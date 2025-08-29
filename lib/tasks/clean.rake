# frozen_string_literal: true

require "rake/clean"

# Clean and clobber tasks
CLEAN.include("coverage/", ".rspec_status", ".yardoc")
CLOBBER.include("docs/api/", "pkg/")
