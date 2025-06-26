# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Export `checkIterConstraints()`
- Provide `AsIter` type
- Impl `Iter.collectAlloc()`, `Iter.collectBuf()`, `Iter.collectArrayList()` and `Iter.collectArrayListAligned()`
- Impl `Iter.scan()`

### Changed

- Pass `self` directly to `Cycle.wrapped.iter` in `Iter.cycle()`
- Struct marking now uses a generic type `Marker`
- Allow infinite range in `fromRangeStep`
- Panic instead of asserting where applicable
- Restructured code
- Rename `lazyOnce()` and `lazyRepeat()` to `onceWith()` and `repeatWith()` respectively
- `assertIsIter()` now returns an error union
- Use `Marker` for all adapters
- Rename `assertIsIter()` to `expectImplIter()`
- Bump `.minimum_zig_version` to 0.14.1
- Use `anytype` for `Iter.fold()`, `Iter.fallibleFold()` and `Iter.scan()`

### Removed

- Remove incorrect overrides for `RepeatWith`
- Remove incorrect overrides for `Cycle`
- Remove `min()` and `max()` from `math_extra.zig` in favor of `@min()` and `@max()`
- Remove `Iter.collect()`

### Fixed

- Overflow error handling in `Chain`
- Fix doc-comments in `Iter`
- `AsIter` type checking
- Error names in `expectImplIter()`
- Improved consistency in code construct representation in `CHANGELOG.md`
- `Repeat.count()` now loops forever
- Override `Map.advanceBy()`, `Skip.count()`, `Take.count()`

## [0.5.0] - 2025-06-02

### Added

- Implement `Iter.any()` and `Iter.all()`
- Doc comments
- Created [docs](docs) directory
- Relative links in [CHANGELOG.md](CHANGELOG.md)

### Changed

- Assert if `other` parameter in `Iter.chain()` and `Iter.zip()` is an iterator
- Rename `Iter.impl` to `Iter.wrapped`
- Make `Iter.advanceBy()` public
- Make `Iter.advanceBy()`, `Iter.nth()` and `Iter.count()` overridable
- Override `Iter.advanceBy()`, `Iter.nth()` and `Iter.count()` for most initializers
- Move documentation for Methods on Iter to [docs/METHODS-ON-ITER.md](docs/METHODS-ON-ITER.md)
- Override `Iter.advanceBy()` for `Enumerate`, `Take`, `Cycle`
- Make `Iter.advanceBy()` return a `usize` representing how much the iterator was not advanced if it is consumed.
- Override `Iter.advanceBy()` for `Chain`
- Override `Iter.advanceBy()` for `Zip`
- `Iter.fallibleReduce()` is now public, but experimental
- Override `Iter.advanceBy()` for `Skip`
- Return `null` in `.peek()` and `.next()` if `Peekable.peeked.?` is `null`
- Override `Iter.advanceBy()` for `Peekable`
- Override `Iter.advanceBy()` for `SkipEvery`
- Override `Iter.advanceBy()` for `StepBy`
- Override `Iter.count()` for `Enumerate`, `Map`, `Chain`, `Peekable` and `Cycle`

### Fixed

- Changed type of `Peekable.peeked` field from `?Item` to `??Item` to fix incorrect size hint
- Assertion for `fromRangeStep()` finite range was incorrect as it could lead to an overflow error
- `FromRange` worked only for unsigned integer types
- Fixed incorrect release years in [CHANGELOG.md](CHANGELOG.md)

## [0.4.0] - 2025-05-22

### Added

- Implement `Iter.fallibleForEach()` and `Iter.fallibleFold()`
- Implement `Iter.fallibleReduce()` as private, experimental methods

### Changed

- Make `Iter.sizeHint()` public but still experimental
- Make `Peekable`, `Take`, `Cycle`, `Skip`, `SkipEvery` and `StepBy` not wrap themselves when chained.
- Make all `fn` parameters `*const`

### Removed

- `Take.curr` field is no longer needed
- `RepeatN.curr` field is no longer needed

### Fixed

- Fixed tests names
- Fixed some `.sizeHint()` implementations in adapters
- Fixed `reiter.recurse()` example in README

## [0.3.0] - 2025-05-20

### Added

- Implement `Iter.skip()` and `Iter.skipWhile()`
- Created this changelog file
- Added `Iter.sizeHint()` and `Iter.collect()` as private, experimental methods

### Fixed

- Re-exported missing `fromRangeStep()` function in [src/root.zig](src/root.zig)
- Changed wording and remove `other` parameter from `.peekable()` in README

## [0.2.0] - 2025-05-17

### Changed

- Renamed `Iter.skip()` to `Iter.skipEvery()`

### Fixed

- `Iter.skipEvery()` no longer panics with parameter 0
- Fixed tests' actual and expected values

## [0.1.2] - 2025-05-14

### Changed

- `Iter.skip()` and `Iter.stepBy()` now panics with a parameter of value 0

### Fixed

- Fixed typo in README

## [0.1.1] - 2025-05-13

### Changed

- Improved comptime assertions for implementations of `Iter`

## [0.1.0] - 2025-05-13

- Initial Release
