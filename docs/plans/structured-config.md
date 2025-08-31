# Structured Configuration - Fasti Development Plan

## ⚠️ Development Order Notice
**This plan depends on positional arguments implementation being completed first.** 

The positional arguments feature (see `positional-arguments.md`) removes `--month` and `--year` options from the CLI interface and simplifies the Options structure to `Options = Data.define(:format, :start_of_week, :country, :style)`. This plan assumes that change has been implemented.

**Prerequisite**: Complete implementation of positional arguments before starting dry-configurable integration.

## Overview
Replace current shell-argument based configuration file (`~/.config/fastirc`) with Ruby-based configuration using dry-configurable and add validation using dry-validation.

## Goals
1. **Structured Configuration**: Replace shell arguments with Ruby DSL
2. **Validation**: Catch configuration errors with helpful messages
3. **Maintainability**: Easier to extend and modify configuration options
4. **User Experience**: Better error reporting for invalid configurations

## Current Architecture
```ruby
# Current fastirc (shell arguments) - after positional args implementation
--format year --country US --start-of-week monday

# Current Options structure (simplified by positional args feature)
Options = Data.define(:format, :start_of_week, :country, :style)
```

## Target Architecture
```ruby
# New fastirc (Ruby DSL)
configure do |config|
  config.format = :year
  config.country = :US
  config.start_of_week = :monday
  config.style.sunday = { bold: true }
  config.style.holiday = { foreground: :red, bold: true }
  config.style.today = { inverse: true }
end

# Configuration priority: Positional args > CLI options > Config file > Locale detection > Defaults
# Options structure simplified (no month/year fields)
```

## Development Phases

### Phase 1: Foundation Setup
**Branch**: `feature/structured-config`

1. **Dependencies**
   - Add to Gemfile:
     ```ruby
     gem 'dry-configurable', '~> 1.0'
     gem 'dry-validation', '~> 1.10'
     # dry-schema will be installed automatically as dependency
     ```
   - Run `bundle install`

2. **Extract and Enhance Options Class**
   - File: `lib/fasti/options.rb`
   - Extract `Options = Data.define(:format, :start_of_week, :country, :style)` from CLI class
   - Add comprehensive option parsing responsibility:
     ```ruby
     def self.parse(argv)
       # Parse remaining command line arguments (positional args handled separately)
       # Load environment variables  
       # Load configuration file
       # Merge with priority: CLI options > Config file > Environment > Defaults
       # Return [remaining_args, options_instance]
     end
     ```
   - Move validation methods from CLI class (except month/year validation)
   - Move environment detection from CLI class

3. **Create Configuration Class**
   - File: `lib/fasti/config.rb`
   - Extend `Dry::Configurable`
   - Define settings with defaults (no month/year settings):
     ```ruby
     setting :format, default: :month
     setting :country, default: -> { detect_country_from_locale || :us }
     setting :start_of_week, default: :sunday
     setting :style, default: {}
     ```

4. **Create Validation Contract**
   - File: `lib/fasti/config_contract.rb`
   - Define schema and custom rules (no month/year validation):
     ```ruby
     class Fasti::ConfigContract < Dry::Validation::Contract
       params do
         optional(:format).value(included_in?: [:month, :quarter, :year])
         optional(:country).value(:symbol)
         optional(:start_of_week).value(included_in?: VALID_WEEKDAYS)
         optional(:style).hash
       end
       
       rule(:country) do
         # Custom validation for country codes
       end
     end
     ```

### Phase 2: Configuration Loading
5. **Ruby Config File Loading**
   - Modify `CLI#load_config_options` method
   - Change from shell argument parsing to Ruby file evaluation
   - Add safety measures for code execution
   - Handle syntax errors gracefully

6. **Configuration Validation**
   - Integrate validation contract
   - Provide user-friendly error messages
   - Handle validation failures gracefully

### Phase 3: Integration
7. **Simplify CLI Class**
   - Replace complex option parsing with `Options.parse(argv)`
   - Remove moved methods (validation, environment detection, option parsing)
   - Focus CLI on calendar generation and output
   - Maintain backward compatibility of command-line interface

8. **Finalize Options Integration**
   - Integrate Options.parse() with dry-configurable system
   - Ensure proper error handling for invalid configurations
   - Test integration between Options parsing and validation
   - Maintain compatibility with Calendar and Formatter classes

### Phase 4: Testing and Documentation
9. **Comprehensive Testing**
   - Test configuration loading and validation
   - Test priority logic (CLI overrides config file)
   - Test error handling for invalid configurations
   - Test backward compatibility

10. **Update Documentation**
   - README.md: New configuration format examples
   - Migration guide from old format
   - Error message explanations

11. **Quality Assurance**
    - RuboCop compliance
    - All tests passing
    - Performance impact assessment

### Phase 5: Deployment
12. **Create Pull Request**
    - Comprehensive description of changes
    - Migration instructions
    - Breaking changes documentation

## Technical Implementation Details

### Configuration File Location
- Remains: `~/.config/fastirc` (XDG compliant)
- Format changes from shell arguments to Ruby DSL

### Validation Rules
```ruby
# Format validation
format: [:month, :quarter, :year]

# Country validation  
country: Valid ISO country codes or symbols

# Start of week validation
start_of_week: [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

# Style validation
style: Hash with valid day types and style attributes

# Note: Month/year validation removed - handled by positional arguments
```

### Error Handling
- Configuration file syntax errors
- Invalid configuration values
- Missing required dependencies
- Graceful fallback to defaults

### Implementation Notes
- No backward compatibility needed (pre-release project)
- Direct transition to new Ruby-based format
- Focus on clear documentation for new format

## Configuration Format Change
Since this project hasn't been officially released yet, we can change the configuration format without backward compatibility concerns.

### Configuration Format
```bash
# Old format (~/.config/fastirc) - after positional args implementation
--format quarter --country JP --start-of-week monday

# New format (~/.config/fastirc)  
configure do |config|
  config.format = :quarter
  config.country = :JP
  config.start_of_week = :monday
end
```

## Risk Assessment
- **Low Risk**: Pre-release project allows breaking changes
- **Low Risk**: Options structure simplified by positional args implementation
- **Low Risk**: CLI interface for non-month/year options unchanged
- **Mitigation**: Clear documentation and helpful error messages

## Success Criteria
- [ ] All existing functionality preserved
- [ ] New Ruby-based configuration working
- [ ] Comprehensive validation with clear error messages  
- [ ] Documentation updated with examples
- [ ] All tests passing
- [ ] Performance maintained or improved
- [ ] User migration path clearly documented

## Files to Modify
- `lib/fasti/cli.rb` - Configuration loading logic
- `lib/fasti.rb` - Add new config class require
- `Gemfile` - Add dry-validation dependency
- `README.md` - Update configuration documentation
- `spec/fasti/cli_spec.rb` - Update tests

## Files to Create
- `lib/fasti/options.rb` - Extracted Options class
- `lib/fasti/config.rb` - Main configuration class
- `lib/fasti/config_contract.rb` - Validation contract
- `spec/fasti/options_spec.rb` - Options tests
- `spec/fasti/config_spec.rb` - Configuration tests
- `spec/fasti/config_contract_spec.rb` - Validation tests

---
*This plan serves as a comprehensive roadmap for implementing dry-configurable integration while maintaining backward compatibility and user experience.*