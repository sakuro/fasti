## [Unreleased]

### Added
- **Core Calendar Application**: Flexible calendar application with multi-country holiday support
- **Multiple Display Formats**: Month, quarter (3 months), and full year views
- **Holiday Support**: Country-specific holiday highlighting using the holidays gem
- **Configurable Week Start**: Support for all 7 days of the week as week start
- **Custom Styling System**: Comprehensive `--style` option with flexible styling rules for holidays, weekends, and today's date
- **Configuration File**: XDG-compliant configuration file support (`~/.config/fastirc`)
- **Locale Detection**: Automatic country detection from `LC_ALL` and `LANG` environment variables
- **Examples Directory**: Sample configuration files for easy setup

### Performance
- **Holiday Caching**: Implement month-based holiday caching for 12-74x performance improvement
- **Bulk API Calls**: Replace per-day holiday lookups with efficient batch retrieval

### Development
- **Comprehensive Testing**: Full RSpec test suite with 154+ examples
- **Code Quality**: RuboCop configuration with strict style enforcement
- **Benchmark Suite**: Performance testing tools for holiday caching validation
- **CI/CD**: GitHub Actions workflow for automated testing and quality checks

## [0.1.0] - 2025-08-25

- Initial release
