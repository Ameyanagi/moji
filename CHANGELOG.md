# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and uses semantic versioning after the first public release.

## [Unreleased]

### Added

- Initial experimental repository scaffold.
- Experimental `ByteRange`, UTF-8 boundary validation, and safe text slicing
  APIs with CJK, emoji, combining-mark, and invalid-range coverage, including
  direct construction from typed `ByteOffset` endpoints.
- Nominal nonnegative byte-offset, code-point-index, grapheme-index, and
  display-column values with same-unit comparison and compile-fail unit checks.
- Constructor-established invariants, trusted non-raising reads, and explicit
  `validate()` checkpoints across validated range and position types.
- Diagnostic-specific mixed-unit compile failures and per-unit extreme-order
  regression coverage.
- An issue-sized v0.1 execution plan with dependency and release gates.
