# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Implement .skip()
- Implement .skipWhile()
- Created this changelog file

## [0.2.0] - 2025-05-17

### Changed

- rename .skip() to .skipEvery()

### Fixed

- .skipEvery() no longer panics with parameter 0
- fixed test actual and expected values

## [0.1.2] - 2025-05-14

### Changed

- .skip() and .stepBy() now panics with a parameter of value 0

### Fixed

- docs typo 

## [0.1.1] - 2025-05-13

### Changed

- Improved comptime assertions for implementations of Iter

## [0.1.0] - 2025-05-13

- Initial Release