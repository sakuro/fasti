# TODO

## New Features
- [ ] Structured configuration file format using dry-configurable
- [ ] I18n of day names, month names, and help messages (gettext?)
- [ ] Support for multiple countries' holidays simultaneously
- [ ] Extract Style class into independent gem
- [ ] Configurable Julian to Gregorian calendar transition date

## Code Quality Improvements (Post Positional Arguments)
- [ ] Optimize method arguments in calendar generation methods
  - Currently `generate_*_calendar` methods receive full `options` object but only use `options.country`
  - Should pass only required `country` parameter for clearer dependencies
- [ ] Fix Time.now consistency during command execution
  - Multiple `Time.now` calls can cause inconsistent results when crossing month/year boundaries
  - Should call `Time.now` once at start and pass to all dependent methods
- [ ] Extract Options class to separate file
  - Move `Options = Data.define(...)` from `lib/fasti/cli.rb` to `lib/fasti/options.rb`
  - Better separation of concerns and clearer architecture
- [ ] Restore coverage threshold to 70%
  - Currently temporarily lowered to 69.5% for positional arguments feature
  - Add more tests to achieve proper coverage for new code

## Maintenance
- [ ] Improve test coverage
- [ ] Reduce RuboCop TODO violations
