# Repository Guidelines

> **Note**: This file is also accessible via the `CLAUDE.md` symlink for AI agent compatibility.

> **Important**: This document references other documentation files. Please also read:
> - `docs/agents/rubocop.md` - RuboCop fix guidelines for AI agents
> - `docs/agents/git-pr.md` - Git commit and pull request guidelines
> - `docs/agents/languages.md` - Language usage guidelines for communication and code
> - Any other documents referenced inline below

## Project Structure & Module Organization
- `lib/fasti`: Core library. Entry point is `lib/fasti.rb`; code is namespaced under `Fasti` (autoloaded via Zeitwerk).
- `spec`: RSpec tests. Mirror library paths (e.g., `spec/fasti/cli_spec.rb`).
- `docs/api`: Generated YARD documentation. Do not edit by hand; use `rake doc`.
- `benchmark/*`: Performance experiments and notes.
- `bin`: Development helpers (`bin/setup`, `bin/console`).

## Build, Test, and Development Commands
- `bundle install`: Install dependencies (use a supported Ruby; see policy below and `mise.toml`).
- `rake`: Default task; runs `spec` and `rubocop`.
- `rake spec`: Run the test suite.
- `rubocop` or `rake rubocop`: Lint and style checks.
- `rake doc`: Build YARD docs into `docs/api`.
- `bin/console`: IRB with the gem loaded for quick experiments.
- `docquet regenerate-todo`: Regenerate `.rubocop_todo.yml` after lint updates; include with related code fixes.

## Communication & Languages
See `docs/agents/languages.md` for detailed language usage guidelines covering:
- AI/user chat communication languages
- Source code and documentation language requirements  
- Issues/PRs language preferences
- Context-appropriate language switching

## Coding Style & Naming Conventions
- Ruby 3.x compatible; 2-space indent, `# frozen_string_literal: true` headers.
- Follow RuboCop rules (`.rubocop.yml`); fix offenses before committing.
- Files and specs use snake_case; specs live under `spec/fasti/*_spec.rb`.
- Public API is under `Fasti`; avoid monkey patching. Prefer immutable, composable objects where applicable.
- RuboCop fixes: When addressing lints, follow `docs/agents/rubocop.md` (safe autocorrect first; targeted unsafe only as needed).

## Testing Guidelines
- Framework: RSpec with `spec_helper` and SimpleCov. Maintain ≥ 90% coverage.
- Name/spec files to mirror library paths; keep examples focused and readable.
- Run `rake spec` locally; ensure `.rspec_status` is clean.

## Commit & Pull Request Guidelines
- Title format: Must start with a GitHub `:emoji:` code followed by a space, then an imperative subject. Example: `:zap: Optimize Style#call path`.
- No raw emoji: Use `:emoji:` codes only (commit hook rejects Unicode emoji).
- Exceptions: `fixup!` / `squash!` are allowed by hooks.
- Merge commits: Auto-prefixed with `:inbox_tray:` by the prepare-commit-msg hook.
- Commit body: English, explaining motivation, approach, and trade-offs.
- Include rationale and, when useful, before/after snippets or benchmarks.
- Link issues (e.g., `Fixes #123`) and update README/CHANGELOG when user-facing behavior changes.
- PRs must pass `rake` (tests + lint), include tests for changes, and keep API docs current (`rake doc` when needed).

## Security & Configuration Tips
- Supported Ruby: latest patch of the newest three minor series (e.g., 3.4.x / 3.3.x / 3.2.x). Develop locally on the oldest of these.
- Version management: Use `mise`; the repo’s `mise.toml` sets the default to the oldest supported series. Examples: `mise use -g ruby@3.2`, `mise run -e ruby@3.3 rake spec`.
- Keep runtime dependencies minimal; prefer standard library where possible.
- No network access is expected at runtime; avoid introducing it without discussion.
