# frozen_string_literal: true

require_relative "lib/fasti/version"

Gem::Specification.new do |spec|
  spec.name = "fasti"
  spec.version = Fasti::VERSION
  spec.authors = ["OZAWA Sakuro"]
  spec.email = ["10973+sakuro@users.noreply.github.com"]

  spec.summary = "A flexible calendar application with multi-country holiday support"
  spec.description = "A Ruby calendar gem with multiple formats and holiday highlighting for many countries"
  spec.homepage = "https://github.com/sakuro/fasti"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.9"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) {|ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies for fasti implementation
  spec.add_dependency "dry-configurable", "~> 1.0"
  spec.add_dependency "dry-schema", "~> 1.13"
  spec.add_dependency "dry-types", "~> 1.7"
  spec.add_dependency "holidays", "~> 8.0"
  spec.add_dependency "locale", "~> 2.1"
  spec.add_dependency "tint_me", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
