# Positional Arguments - Fasti Development Plan

## Overview
Replace current option-based month/year specification (`--month`/`--year`) with positional arguments to provide a more intuitive command-line interface.

## Goals
1. **Simplified Interface**: Remove `--month` and `--year` options in favor of positional arguments
2. **Intuitive Usage**: Natural argument parsing that matches user expectations  
3. **Backward Compatibility**: Maintain all other existing functionality
4. **User Experience**: Clear error messages for invalid argument combinations

## Current Architecture
```bash
# Current option-based interface
fasti --month 6 --year 2024           # June 2024
fasti --month 6                       # June current year
fasti --year 2024                     # Current month 2024
fasti                                 # Current month/year

# Current Options structure (month/year will be removed)
Options = Data.define(:month, :year, :format, :start_of_week, :country, :style)
```

## Target Architecture
```bash
# New positional argument interface
fasti 6 2024                          # June 2024 (month year)
fasti 6                               # June current year (1-12 = month)
fasti 2024                            # Current month 2024 (13+ = year)
fasti                                 # Current month/year

# Argument parsing rules:
# 0 args: current month + current year
# 1 arg:  1-12 → month + current year, 13+ → current month + year
# 2 args: first = month (any value), second = year
#         month must be 1-12 or ArgumentError

# Options structure simplified (month/year removed)
Options = Data.define(:format, :start_of_week, :country, :style)
```

## Development Phases

### Phase 1: Foundation Setup
**Branch**: `feature/positional-arguments`

1. **Update Options Structure**
   - Remove `:month` and `:year` from Options Data.define
   - Update Options structure: `Options = Data.define(:format, :start_of_week, :country, :style)`
   - Update all usages of Options throughout codebase

2. **Update CLI Argument Processing**
   - Remove `--month` and `--year` option definitions from OptionParser
   - Update CLI class documentation to reflect new interface
   - Update help text to show positional argument usage

3. **Implement Positional Argument Parser**
   - File: `lib/fasti/cli.rb`
   - Add `parse_positional_args(argv)` method:
     ```ruby
     def parse_positional_args(argv)
       case argv.length
       when 0
         # Use current month and year
         [Time.now.month, Time.now.year]
       when 1
         arg = argv[0].to_i
         validate_single_argument!(arg)
         if (1..12).include?(arg)
           [arg, Time.now.year]  # Month for current year
         else
           [Time.now.month, arg]  # Year for current month
         end
       when 2
         month = argv[0].to_i
         year = argv[1].to_i
         validate_month!(month)
         validate_year!(year)
         [month, year]
       else
         raise ArgumentError, "Too many arguments. Expected 0-2, got #{argv.length}"
       end
     end
     ```

4. **Add Validation Methods**
   - Add `validate_single_argument!(arg)` for single argument validation
   - Enhance existing `validate_month!` and `validate_year!` methods
   - Ensure clear error messages for invalid inputs

### Phase 2: Integration
5. **Modify Option Parsing Flow**
   - Update `parse_options(argv)` method to:
     1. Parse options first with modified OptionParser (without --month/--year)
     2. OptionParser.parse! automatically removes processed options from argv
     3. Parse remaining arguments (now only positional) to extract month/year values
     4. Pass month/year separately to calendar generation methods

6. **Update Calendar Generation Methods**
   - Modify `generate_calendar`, `generate_month_calendar`, `generate_quarter_calendar`, `generate_year_calendar`
   - Accept month and year as separate parameters instead of from Options struct
   - Remove month/year access from Options throughout calendar generation logic

7. **Update Default Options Logic**
   - Remove month/year from `default_options` method
   - Simplify Options structure to only include format, start_of_week, country, style
   - Handle month/year defaults in positional argument parsing

### Phase 3: Testing and Documentation
8. **Comprehensive Testing**
   - Test all argument combinations (0, 1, 2 arguments)
   - Test error cases (invalid months, negative years, too many arguments)
   - Test integration with other options (`--format`, `--country`, etc.)
   - Ensure backward compatibility for non-month/year options
   - Test Options structure changes don't break existing functionality

9. **Update Documentation**
   - CLI class documentation: Update method comments and examples
   - Help text: Show new positional argument usage
   - README.md: Update usage examples throughout

10. **Quality Assurance**
    - RuboCop compliance
    - All tests passing
    - Manual testing of common use cases
    - Error message clarity verification

### Phase 4: Deployment
11. **Create Pull Request**
    - Comprehensive description of interface change
    - Breaking change documentation
    - Migration examples for common usage patterns

## Technical Implementation Details

### Design Decisions

#### Argument Order for Two Arguments
**Decision**: Fixed positional order (first argument = month, second argument = year)

**Alternative Considered**: Automatic order detection (larger value = year, smaller value = month)

**Rationale for Fixed Order**:
- **Predictable behavior**: Users know exactly what `fasti 6 2024` means
- **Standard CLI convention**: Most command-line tools use fixed positional argument order
- **Clear error handling**: Invalid month (e.g., `fasti 13 2024`) immediately produces a clear error message
- **No hidden corrections**: Invalid input fails explicitly rather than being "corrected" silently
- **Easier debugging**: Behavior is deterministic and traceable

**Problems with Automatic Detection**:
- **Ambiguous error cases**: `fasti 13 2024` would be interpreted as "2024 year, 13 month" and fail in a confusing way
- **Unexpected behavior**: Users might not understand why `fasti 25 2024` becomes "2024 year, 25 month"
- **Debugging complexity**: Non-obvious transformations make troubleshooting difficult

### Argument Parsing Logic
```ruby
# Option parsing flow
def parse_options(argv)
  options_hash = default_options.to_h
  
  # 1. Parse options first - removes them from argv automatically
  parser = create_option_parser(options_hash, include_help: true)
  parser.parse!(argv)  # Destructively modifies argv
  
  # 2. Parse remaining positional arguments
  month, year = parse_positional_args(argv)
  
  # 3. Create options and return with month/year
  options = Options.new(**options_hash)
  [month, year, options]
end

# Positional argument parsing (after options removed)
def parse_positional_args(argv)
  case argv.length
  when 0
    [Time.now.month, Time.now.year]
  when 1
    interpret_single_argument(argv[0])
  when 2
    validate_two_arguments(argv[0], argv[1])
  else
    raise ArgumentError, "Too many arguments. Expected 0-2, got #{argv.length}"
  end
end

# Single argument interpretation
def interpret_single_argument(arg)
  value = arg.to_i
  if value == 0 && arg != "0"
    raise ArgumentError, "Invalid argument: '#{arg}'. Expected integer."
  end
  
  if (1..12).include?(value)
    [value, Time.now.year]  # Return [month, current_year]
  elsif value >= 13
    [Time.now.month, value]  # Return [current_month, year]
  else
    raise ArgumentError, "Invalid argument: #{value}. Expected 1-12 (month) or 13+ (year)."
  end
end

# Two argument validation
def validate_two_arguments(month_arg, year_arg)
  month = month_arg.to_i
  year = year_arg.to_i
  
  raise ArgumentError, "Invalid month: '#{month_arg}'" if month == 0 && month_arg != "0"
  raise ArgumentError, "Invalid year: '#{year_arg}'" if year == 0 && year_arg != "0"
  
  validate_month!(month)
  validate_year!(year)
  
  [month, year]  # Return [month, year]
end
```

### Updated CLI Interface Examples
```bash
# Display current month
fasti

# Display June of current year
fasti 6

# Display current month of 2024
fasti 2024

# Display June 2024
fasti 6 2024

# Display with other options (unchanged)
fasti 6 2024 --format year --country US
fasti 12 --start-of-week monday
```

### Error Handling
```bash
# Invalid month in two-argument case
$ fasti 13 2024
Error: Month must be between 1 and 12

# Too many arguments
$ fasti 6 2024 extra
Error: Too many arguments. Expected 0-2, got 3

# Invalid single argument (edge cases)
$ fasti 0
Error: Invalid argument: 0. Expected 1-12 (month) or 13+ (year).

$ fasti -5
Error: Invalid argument: -5. Expected 1-12 (month) or 13+ (year).
```

### Integration Notes
- Options structure simplified to `Options = Data.define(:format, :start_of_week, :country, :style)`
- All other CLI options (`--format`, `--country`, etc.) work identically  
- Configuration file support unchanged (month/year options will be ignored if present)
- Calendar generation methods modified to accept month/year as separate parameters

## Risk Assessment
- **Medium Risk**: Breaking change to CLI interface and Options structure
- **Medium Risk**: Internal API changes to calendar generation methods
- **Low Risk**: Core functionality preserved, only interface changes
- **Mitigation**: Clear documentation and helpful error messages

## Success Criteria
- [ ] Options structure updated to remove month/year fields
- [ ] All existing functionality preserved (except `--month`/`--year` options)  
- [ ] New positional argument parsing working correctly
- [ ] Calendar generation methods updated to accept month/year as parameters
- [ ] Comprehensive error handling with clear messages
- [ ] Documentation updated with examples
- [ ] All tests passing
- [ ] Documentation updated with new interface examples
- [ ] Help text and CLI documentation updated

## Files to Modify
- `lib/fasti/cli.rb` - Main CLI argument processing and Options structure
- `README.md` - Update usage examples
- `spec/fasti/cli_spec.rb` - Update tests for new interface
- Any files that reference `options.month` or `options.year` (to be identified during implementation)

## Breaking Changes
- **Removed Options**: `--month` and `--year` options no longer available
- **Options Structure**: `Options` no longer contains `:month` and `:year` fields
- **Internal API**: Calendar generation methods now accept month/year as separate parameters
- **New Interface**: Must use positional arguments for month/year specification
### Interface Examples
```bash
# New positional argument interface
fasti 6 2024                          # June 2024
fasti 6                               # June current year
fasti 2024                            # Current month 2024
fasti                                 # Current month/year

# Combined with other options
fasti 6 --format year                 # June current year with year format
fasti 2024 --country US               # Current month 2024 with US holidays
```

---
*This plan serves as a comprehensive roadmap for implementing positional arguments while maintaining the core functionality.*