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
- [ ] **URGENT: Fix time-dependent test failures**
  - Tests depend on current month/year (`Time.now`) which causes failures across date boundaries
  - **Risk**: Tests will fail starting October 1st, 2025 (current date: September 1st)
  - **Solution**: Use `timecop` gem to freeze time in tests (safer than `allow` stub which doesn't auto-restore)
  - **Implementation**: Add `gem 'timecop', group: :test` and use `Timecop.freeze(Time.new(2024, 9, 1)) do ... end`
  - **Affected tests**: "displays calendar for specified year (current month)" and similar time-dependent cases

## Maintenance
- [ ] Improve test coverage
- [ ] Reduce RuboCop TODO violations
