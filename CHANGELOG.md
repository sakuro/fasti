## [Unreleased]

### Added
- **Core Calendar Application**: Flexible calendar application with multi-country holiday support
- **Multiple Display Formats**: Month, quarter (3 months), and full year views
- **Holiday Support**: Country-specific holiday highlighting using the holidays gem
- **Configurable Week Start**: Support for all 7 days of the week as week start
- **Custom Styling System**: Comprehensive `--style` option with flexible styling rules for holidays, weekends, and today's date powered by TIntMe gem
- **Configuration File**: XDG-compliant Ruby-based configuration file support (`~/.config/fasti/config.rb`)
- **Locale Detection**: Automatic country detection from `LC_ALL` and `LANG` environment variables
- **Examples Directory**: Sample configuration files for easy setup
- **Zeitwerk Integration**: Modern code autoloading with Zeitwerk for improved performance and maintainability

### Performance
- **Holiday Caching**: Month-based holiday caching with bulk API calls for 12-74x performance improvement
- **Style Caching**: Target-based style caching system achieving 966+ months/second rendering performance
- **TIntMe Integration**: High-performance ANSI terminal styling with optimized color composition

### Development
- **Comprehensive Testing**: Full RSpec test suite with 154+ examples
- **Code Quality**: RuboCop configuration with strict style enforcement
- **Benchmark Suite**: Performance testing tools for holiday caching validation
- **CI/CD**: GitHub Actions workflow for automated testing and quality checks
