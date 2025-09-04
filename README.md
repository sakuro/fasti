# Fasti

A flexible calendar application with multi-country holiday support, written in Ruby. Fasti provides beautiful, colorful calendar displays with support for multiple output formats, configurable week start days, and country-specific holiday highlighting.

## Features

- **Multiple Display Formats**: Month, quarter (3 months), and full year views
- **Configurable Week Start**: Start weeks on any day of the week
- **Holiday Support**: Country-specific holiday highlighting using the holidays gem
- **Historical Calendar Transitions**: Julian to Gregorian calendar transitions with country-specific gap handling
- **Color Coding**: ANSI color support for holidays, weekends, and today's date
- **Configuration File**: XDG-compliant Ruby-based configuration file support (`~/.config/fasti/config.rb`)
- **Locale Detection**: Automatic country detection from `LC_ALL` and `LANG` environment variables
- **Command Line Interface**: Full-featured CLI with comprehensive options

## Installation

Install the gem by executing:

```bash
gem install fasti
```

Or add it to your Gemfile:

```ruby
gem 'fasti'
```

Then execute:

```bash
bundle install
```

## Usage

### Basic Usage

Display the current month:
```bash
fasti
```

Display a specific month and year:
```bash
fasti 6 2024
```

### Display Formats

**Month View** (default):
```bash
fasti 6 2024 --format month
# Or using shortcuts:
fasti 6 2024 --month
fasti 6 2024 -m
```

**Quarter View** (3 months side by side):
```bash
fasti 6 2024 --format quarter
# Or using shortcuts:
fasti 6 2024 --quarter
fasti 6 2024 -q
```

**Year View** (all 12 months):
```bash
fasti 2024 --format year
# Or using shortcuts:
fasti 2024 --year
fasti 2024 -y
```

### Week Start Configuration

You can start the week on any day of the week:

```bash
fasti --start-of-week sunday     # Default
fasti --start-of-week monday     # Common international standard
fasti --start-of-week tuesday
fasti --start-of-week wednesday
fasti --start-of-week thursday
fasti --start-of-week friday
fasti --start-of-week saturday
```

### Country and Holiday Support

Specify country for holiday highlighting:
```bash
fasti --country JP    # Japan
fasti --country US    # United States
fasti --country GB    # United Kingdom
fasti --country DE    # Germany
```

Fasti automatically detects your country from environment variables (`LC_ALL`, `LANG`), but you can override this with the `--country` option.

### Historical Calendar Transitions

For historical dates, Fasti supports country-specific Julian to Gregorian calendar transitions with proper gap handling:

```bash
# Show October 1582 (Italian transition) - compressed gaps (default)
fasti 10 1582 --country IT

# Show gaps historically - October 5-14, 1582 never existed in Italy
fasti 10 1582 --country IT --show-gaps

# British transition - September 3-13, 1752 never existed in Britain
fasti 9 1752 --country GB --show-gaps

# Asian countries transitioned from lunisolar calendars
# Japan transitioned in 1873 (Meiji era)
fasti 12 1872 --country JP --show-gaps

# Korea transitioned in 1896 (Korean Empire era)
fasti 12 1895 --country KR --show-gaps

# France had different transition date than Italy
fasti 12 1582 --country FR --show-gaps

# Sweden's complex transition in 1753
fasti 3 1753 --country SE --show-gaps
```

**Gap Display Options:**
- `--show-gaps`: Show calendar transition gaps as empty spaces
- `--no-show-gaps` (default): Compress gaps like UNIX `cal` command for continuous display

Supported countries with calendar transition dates:

**Early Catholic adoption (1582-1583):**
- Italy, Spain, Portugal (1582-10-15)
- France (1582-12-20) 
- Belgium/Spanish Netherlands (1583-01-06)

**Protestant countries (1700-1753):**
- Netherlands (1700-07-12), Switzerland (1700-01-23), Denmark/Norway (1700-03-01)
- Great Britain & colonies: US, Canada, Australia, etc. (1752-09-14)
- Sweden (1753-03-01)

**Eastern Europe (1916-1927):**
- Bulgaria (1916), Russia (1918), Romania/Yugoslavia (1919), Greece (1923), Turkey (1927)

**Asian countries (1873-1967):**
- Japan (1873), China/Taiwan (1912), Korea (1896), Vietnam (1967), Thailand (1888)

Note: Asian countries transitioned from lunisolar calendars to Gregorian; pre-transition dates use proleptic Gregorian calendar for computational consistency.

### Command Line Options

```
Usage: fasti [month] [year] [options]

Arguments:
  month  Month (1-12, optional)
  year   Year (optional)

Format options:
  -f, --format FORMAT           Output format (month, quarter, year)
  -m, --month                   Display month format (equivalent to --format month)
  -q, --quarter                 Display quarter format (equivalent to --format quarter)
  -y, --year                    Display year format (equivalent to --format year)

Calendar display options:
  -w, --start-of-week WEEKDAY   Week start day (any day of the week)
  -c, --country COUNTRY         Country code for holidays (e.g., JP, US, GB, DE)
  -s, --style STYLE             Custom styling (e.g., "sunday:bold holiday:foreground=red today:inverse")
      --[no-]show-gaps          Show calendar transition gaps as empty space (default: compress like UNIX cal)

Other options:
  -v, --version                 Show version
  -h, --help                    Show this help
```

### Positional Arguments

**No arguments** - Display current month:
```bash
fasti
```

**One argument** - Interpreted based on value:
- 1-12: Month for current year
- 13+: Year for current month

```bash
fasti 6        # June current year
fasti 2024     # Current month 2024
```

**Two arguments** - Month and year:
```bash
fasti 6 2024   # June 2024
```

### Configuration File

Create a configuration file at `~/.config/fasti/config.rb` (or `$XDG_CONFIG_HOME/fasti/config.rb`) using Ruby syntax to set default options:

```ruby
# Example configuration
Fasti.configure do |config|
  config.format = :quarter
  config.start_of_week = :monday
  config.country = :US
  config.show_gaps = false  # Default: compress calendar transition gaps
  # Custom styling (optional)
  config.style = {
    sunday: { bold: true },
    holiday: { foreground: :red, bold: true },
    today: { inverse: true }
  }
end
```

See `examples/config.rb` for a complete configuration example.

Command line options override configuration file settings.

### Styling

Fasti uses ANSI text styling to highlight different types of days:

- **Bold**: Sundays and holidays
- **Inverted**: Today's date (combined with bold when applicable)
- **Normal**: Regular weekdays (including Saturdays)

### Examples

Display current month with Monday start:
```bash
fasti --start-of-week monday
```

Display current month with Wednesday start:
```bash
fasti --start-of-week wednesday
```

Show quarter view for summer 2024 in Japan:
```bash
fasti 7 2024 --format quarter --country JP
```

Full year 2024 with US holidays:
```bash
fasti 2024 --format year --country US
```

## Environment Variables

Fasti respects the following environment variables for automatic country detection:

- `LC_ALL` (highest priority)
- `LANG` (fallback)

Example:
```bash
export LANG=ja_JP.UTF-8  # Automatically uses Japan (JP) holidays
fasti
```

## Development

After checking out the repo, run `bin/setup` to install dependencies:

```bash
git clone https://github.com/sakuro/fasti.git
cd fasti
bin/setup
```

Run the tests (includes coverage measurement):
```bash
bundle exec rake spec
```

Run linting:
```bash
bundle exec rake rubocop
```

Generate API documentation:
```bash
bundle exec rake doc
```

Clean temporary files:
```bash
bundle exec rake clean
```

Remove all generated files:
```bash
bundle exec rake clobber
```

Run all checks:
```bash
bundle exec rake
```

To install this gem onto your local machine:
```bash
bundle exec rake install
```

For an interactive prompt that allows you to experiment:
```bash
bin/console
```

## Dependencies

- **holidays** (~> 8.0): Country-specific holiday data
- **paint** (~> 2.0): ANSI color support
- **locale** (~> 2.1): Locale parsing for country detection

## Development Dependencies

- **rspec** (~> 3.0): Testing framework
- **rubocop** (~> 1.21): Code linting
- **simplecov** (~> 0.22): Code coverage measurement
- **yard** (from GitHub): API documentation generation with Data class support

## Releasing

This project uses automated GitHub Actions workflows for releases. Maintainers can create new releases with a simple workflow execution.

### Quick Release Process

1. Go to **Actions** → **Release Preparation** → **Run workflow**
2. Enter version number (e.g., `1.0.0`)
3. Review and merge the generated PR
4. Release is automatically published to RubyGems and GitHub

**For detailed instructions, troubleshooting, and setup requirements, see [`.github/RELEASING.md`](.github/RELEASING.md).**

## Known Limitations

### Historical Calendar Support

Fasti properly handles historical calendar transitions with country-specific transition dates. Each country switched from Julian to Gregorian calendar at different times, and these transition periods contain non-existent dates that are handled correctly.

Historical transition periods display correctly with proper gap handling:

```bash
# Italian transition works correctly - shows gaps or compressed display
fasti 10 1582 --country IT --show-gaps

# Asian countries show transitions from lunisolar calendars
fasti 12 1872 --country JP --show-gaps
```

**Note**: Standard UNIX calendar tools like `cal` and `gcal` correctly handle these historical transitions by appropriately skipping non-existent dates during calendar reforms.

**Technical Details**: Fasti uses country-specific Julian to Gregorian calendar transition dates with proper gap handling. Ruby's `Date` class uses Italy's transition date (`Date::ITALY`) by default, but Fasti's `CalendarTransition` class supports transitions for different countries, properly handling non-existent dates during calendar reforms.

**Available Countries**: Fasti supports **25+ countries** with calendar transitions:
- **Catholic countries**: Italy/Spain/Portugal (1582), France (1582), Belgium (1583)
- **Protestant countries**: Netherlands (1700), Switzerland (1700), Denmark/Norway (1700), Great Britain & colonies (1752), Sweden (1753)  
- **Eastern Europe**: Bulgaria (1916), Russia (1918), Romania/Yugoslavia (1919), Greece (1923), Turkey (1927)
- **Asian countries**: Japan (1873), China/Taiwan (1912), Korea (1896), Vietnam (1967), Thailand (1888)

Asian countries used lunisolar calendars before adoption; pre-transition dates use proleptic Gregorian calendar for computational consistency.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sakuro/fasti.

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rake spec`)
5. Ensure code passes linting (`bundle exec rake rubocop`)
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

- Built with Ruby 3.2+ for broad compatibility and modern features
- Uses the excellent [holidays](https://github.com/holidays/holidays) gem for accurate holiday data
- Color support provided by the [paint](https://github.com/janlelis/paint) gem
- Follows XDG Base Directory Specification for configuration files