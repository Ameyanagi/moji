# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and uses semantic versioning.

## [Unreleased]

### Added

- `GraphemeBoundaryIndex` for owned immutable text with O(1) cluster-to-byte
  and range lookup, O(log n) exact byte-to-cluster conversion, and borrowed
  text/slice views. Existing streaming segmentation remains unchanged.
- Mandatory Unicode 17.0.0 GraphemeBreakTest coverage for all public grapheme
  operations, with pinned fixture/license bytes and nine exact, documented
  Mojo 1.0.0 compatibility exceptions.
- Reproducible small/long CJK and emoji cursor lookup benchmarks.

## [0.1.0] - 2026-08-22

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
- Unicode 17.0.0 terminal-width tables with explicit ambiguous-width policy,
  grapheme-aware measurement, and reproducible data provenance.
- Safe conversion among byte, code-point, grapheme, and display-column
  coordinates, including explicit floor and reject snapping policies.
- Grapheme iteration and slicing that preserve combining sequences, emoji
  modifiers, regional indicators, and zero-width-joiner families.
- `TextIndex` for reusable UTF-8 byte/code-point endpoint conversion with an
  identity-coordinate ASCII representation that retains no endpoint table.
- `MappedText` for exact transformed-scalar-to-source range mappings, including
  expansion, contraction, reordering, and discontiguous highlighting.
- Reproducible indexing and mapping benchmarks plus native sampling-profiler
  workloads.

### Changed

- Add writable coordinate forms, same-unit arithmetic for byte offsets and
  display columns, and a one-code-point `StringSlice` width overload.
- Report argument names, offending values, violated rules, and corrective
  guidance from public validation errors.

### Fixed

- Merge every transitively connected source-range component while preserving
  contributor order and one-byte gaps in `MappedText` queries.

[Unreleased]: https://github.com/Ameyanagi/moji/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Ameyanagi/moji/releases/tag/v0.1.0
