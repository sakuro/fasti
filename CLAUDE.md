# Fasti Project - AI Development Guide

## Project Overview

Fasti is a flexible calendar application with multi-country holiday support, written in Ruby. The project provides beautiful, colorful calendar displays with support for multiple output formats, configurable week start days, and country-specific holiday highlighting.

### Key Features
- **Multiple Display Formats**: Month, quarter (3 months), and full year views
- **Configurable Week Start**: Start weeks on any day of the week
- **Holiday Support**: Country-specific holiday highlighting using the holidays gem
- **Color Coding**: ANSI color support for holidays, weekends, and today's date
- **Configuration File**: XDG-compliant configuration file support (`~/.config/fastirc`)
- **Locale Detection**: Automatic country detection from `LC_ALL` and `LANG` environment variables
- **Command Line Interface**: Full-featured CLI with comprehensive options

## Project Structure

```
fasti/
+-- bin/                        # Development setup scripts
+-- exe/fasti                   # Main executable
+-- lib/fasti/                  # Core library files
    +-- calendar.rb             # Calendar logic
    +-- cli.rb                  # Command line interface
    +-- formatter.rb            # Output formatting
    +-- version.rb              # Version management
+-- spec/                       # Test files
+-- sig/                        # RBS type signatures (if applicable)
+-- tasks/                      # Rake tasks
```

## Technology Stack

- **Ruby**: 3.4+ (modern Ruby features)
- **Core Dependencies**:
  - `holidays` (~> 8.0): Country-specific holiday data
  - `paint` (~> 2.0): ANSI color support
  - `locale` (~> 2.1): Locale parsing for country detection
- **Development Tools**:
  - `rspec` (~> 3.0): Testing framework
  - `rubocop` (~> 1.21): Code style enforcement
  - `tty-command` (~> 0.10): CLI testing support

## Development Commands

### Testing and Quality
```bash
bundle exec rake spec      # Run tests
bundle exec rake rubocop   # Code linting
bundle exec rake          # All checks
```

### Installation and Setup
```bash
bin/setup                 # Development setup
bundle exec rake install # Install locally
bin/console               # Interactive console
```

## :warning: AI Development: Mandatory Pre-Work Checklist

**CRITICAL: These linked files MUST be read before starting any development work**:

- **[Git Workflow Guide](.claude/git-workflow.md)**: Commit message format, git operation constraints (**MANDATORY**)
- **[Project Conventions](.claude/project-conventions.md)**: Project-specific rules (**MANDATORY**)
- **[Code Quality Management](.claude/code-quality.md)**: RuboCop standards and quality gates (**MANDATORY**)
- **[Development Standards](.claude/development-standards.md)**: Language conventions and documentation requirements

**Non-negotiable Rules (frequently violated)**:
- :art: **Emoji Format**: Use `:emoji:` notation only (`:sparkles:` NOT `✨`)
- :file_folder: **Git Add**: Use explicit file paths only (`git add file1.rb file2.rb` NOT `git add .`)
- :wrench: **Before Commits**: Check relevant guidelines above - NO EXCEPTIONS

**:no_entry: DO NOT PROCEED without confirming compliance with these rules**

## AI Development Guidelines

### Communication Standards
- Communicate in Japanese with users
- Use English for all code, comments, and technical documentation
- Follow conventional commit messages in English with emoji notation

### Code Quality Requirements
- All code must pass RuboCop checks before committing
- Maintain test coverage for new functionality
- Follow Ruby community best practices and idioms
- Use descriptive naming for variables, methods, and classes

### Development Workflow
1. **Before Changes**: Run `bundle exec rubocop` and `bundle exec rake spec`
2. **During Development**: Make atomic, logical commits
3. **Before Committing**: Ensure all quality checks pass
4. **Pull Requests**: Include comprehensive descriptions and test plans

### Project-Specific Considerations
- Calendar functionality requires careful date/time handling
- Holiday data integration must be accurate for different countries
- CLI interface should provide clear and helpful error messages
- Color output should degrade gracefully in non-color terminals
- Configuration file handling should follow XDG standards

## Architecture Notes

### Core Components
- **Calendar**: Core date calculation and calendar generation logic
- **CLI**: Command-line argument parsing and user interaction
- **Formatter**: Output formatting with color support and multiple display formats
- **Holiday Integration**: Country-specific holiday detection and highlighting

### Design Principles
- **Modularity**: Clear separation between calendar logic, formatting, and CLI
- **Configurability**: Support for various display formats and customization options
- **Internationalization**: Multi-country holiday support with locale detection
- **User Experience**: Intuitive CLI with helpful defaults and error messages

This guide serves as the primary reference for AI-assisted development on the Fasti project. Always refer to the linked documents in `.claude/` for detailed procedures and standards.
