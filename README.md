# Fasti

A flexible calendar application with multi-country holiday support, written in Ruby. Fasti provides beautiful, colorful calendar displays with support for multiple output formats, configurable week start days, and country-specific holiday highlighting.

## Features

- **Multiple Display Formats**: Month, quarter (3 months), and full year views
- **Configurable Week Start**: Start weeks on Sunday or Monday
- **Holiday Support**: Country-specific holiday highlighting using the holidays gem
- **Color Coding**: ANSI color support for holidays, weekends, and today's date
- **Configuration File**: XDG-compliant configuration file support (`~/.config/fastirc`)
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

Display a specific month:
```bash
fasti --month 6 --year 2024
```

### Display Formats

**Month View** (default):
```bash
fasti --format month --month 6 --year 2024
```

**Quarter View** (3 months side by side):
```bash
fasti --format quarter --month 6 --year 2024
```

**Year View** (all 12 months):
```bash
fasti --format year --year 2024
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

### Command Line Options

```
Usage: fasti [options]

Calendar display options:
  -m, --month MONTH              Month (1-12, default: current)
  -y, --year YEAR               Year (default: current)
  -f, --format FORMAT           Output format (month, quarter, year)
  -w, --start-of-week WEEKDAY   Week start day (any day of the week)
  -c, --country COUNTRY         Country code for holidays (e.g., JP, US, GB, DE)

Other options:
  -v, --version                 Show version
  -h, --help                    Show this help
```

### Configuration File

Create a configuration file at `~/.config/fastirc` (or `$XDG_CONFIG_HOME/fastirc`) to set default options:

```bash
# Example configuration
--format quarter --start-of-week monday --country US
```

See `examples/fastirc` for a complete configuration example.

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
fasti --format quarter --month 7 --year 2024 --country JP
```

Full year 2024 with US holidays:
```bash
fasti --format year --year 2024 --country US
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
- **tty-command** (~> 0.10): CLI testing support
- **yard** (from GitHub): API documentation generation with Data class support

## Releasing

This project uses automated GitHub Actions workflows for releases. Maintainers can create new releases with a simple workflow execution.

### Quick Release Process

1. Go to **Actions** → **Release Preparation** → **Run workflow**
2. Enter version number (e.g., `1.0.0`)
3. Review and merge the generated PR
4. Release is automatically published to RubyGems and GitHub

**For detailed instructions, troubleshooting, and setup requirements, see [`.github/RELEASING.md`](.github/RELEASING.md).**

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

- Built with Ruby 3.4+ for modern performance and features
- Uses the excellent [holidays](https://github.com/holidays/holidays) gem for accurate holiday data
- Color support provided by the [paint](https://github.com/janlelis/paint) gem
- Follows XDG Base Directory Specification for configuration files