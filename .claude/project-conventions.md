# Project Conventions

## Fasti-Specific Guidelines

This document contains conventions and guidelines specific to the Fasti project.

## Development Environment

### Ruby Environment
- Use the Ruby version specified in `.ruby-version`
- Bundle dependencies with `bundle install`
- Run tests with `bundle exec rspec`

### Development Tools
- **RuboCop**: Code style enforcement
- **Steep**: Type checking (if applicable)
- **YARD**: Documentation generation
- **RSpec**: Testing framework

## Project Structure

### Library Organization
- Core functionality in `lib/fasti/`
- Type signatures in `sig/fasti/` (if using RBS)
- Tests in `spec/`
- Documentation in appropriate markdown files
- Main executable in `exe/fasti`

### Naming Conventions
- Use snake_case for file names
- Use PascalCase for class names
- Use SCREAMING_SNAKE_CASE for constants
- Use descriptive names that reflect functionality

## File Management

### Untracked Files Policy

**Configuration and Instruction Files**: 
- Keep necessary instruction files (like `CLAUDE.md`, development guidelines, etc.) untracked if they are not meant to be committed
- These files should remain in the working directory for development purposes
- Do not accidentally commit temporary configuration files

**Best Practices**:
- Use explicit file paths with `git add` to avoid committing untracked files unintentionally
- Regularly review `git status` to understand what files are tracked vs. untracked
- Use `.gitignore` for files that should never be committed (build artifacts, logs, etc.)
- Keep project-specific instruction files accessible but uncommitted when appropriate

**Important Notes**:
- Untracked instruction files should not be deleted unless explicitly requested
- The untracked status is intentional for certain development files
- Always verify what will be committed using `git status` before committing

## Calendar-Specific Guidelines

### Date and Time Handling
- Use Ruby's Date and Time classes appropriately
- Handle timezone considerations carefully
- Ensure accurate calendar calculations across different locales
- Test edge cases (leap years, month boundaries, etc.)

### Holiday Integration
- Leverage the holidays gem for accurate country-specific data
- Validate holiday data for target countries
- Handle cases where holiday data might be unavailable
- Ensure proper locale detection from environment variables

### CLI Interface Design
- Provide clear and helpful error messages
- Implement graceful degradation for color output
- Follow Unix command-line conventions
- Support configuration files following XDG standards

### Color Output Management
- Use the paint gem consistently for color output
- Ensure color output works across different terminal types
- Implement fallback for non-color terminals
- Test color combinations for accessibility

## Error Handling
- Use appropriate exception hierarchy (inherit from Fasti::Error)
- Provide meaningful error messages
- Include relevant context in exceptions
- Handle CLI-specific errors gracefully

## Testing Conventions
- Write comprehensive test coverage for calendar logic
- Test CLI functionality with RSpec output matcher for direct method testing
- Use descriptive test names
- Group related tests logically
- Test both success and failure cases
- Include tests for different locales and countries

## Documentation Requirements
- Document public APIs with YARD
- Include usage examples where appropriate
- Keep documentation up-to-date with code changes
- Use English for all technical documentation
- Document CLI options and configuration file format

## Release Management
- Follow semantic versioning
- Tag releases appropriately
- Maintain CHANGELOG.md
- Ensure all tests pass before release
- Test gem installation process

## CI/CD Integration
- All commits should pass RuboCop checks
- All tests must pass
- Type checking should pass (if applicable)
- Documentation should build successfully
- Test gem building process

## Performance Considerations
- Calendar calculations should be efficient
- Consider memory usage for large date ranges
- Optimize color output for large displays
- Benchmark date/time operations

## Security Guidelines
- Validate all CLI inputs
- Handle configuration file parsing safely
- Follow secure coding practices
- Regular security updates for dependencies

## Dependency Management
- Keep dependencies up-to-date (holidays, paint, locale)
- Justify new dependencies
- Use appropriate version constraints
- Regular security audits

## Special Instructions

### Modification Guidelines
- If an instruction does not fit into existing categories, create a new file in the .claude directory and reference it from CLAUDE.md
- Keep project-specific conventions in this file
- General development standards should go in development-standards.md