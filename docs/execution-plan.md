# v0.1 execution plan

This document turns the v0.1 roadmap into ordered, independently reviewable
work. Each work item should fit one focused pull request. Later items may begin
only when their listed prerequisites and acceptance checks are complete.

## Release outcome

Moji v0.1 is a standard-library-only package that lets callers:

1. name and validate UTF-8 byte ranges;
2. convert among byte, code-point, grapheme, and display-column positions;
3. safely slice text at the requested semantic boundary;
4. measure terminal display width under a documented Unicode data version; and
5. map transformed output ranges back to exact source ranges.

The root package exports only the types and functions required for those tasks.
All offsets are nonnegative and all ranges are half-open. APIs must state
whether they operate on bytes, code points, graphemes, or display columns.

## Cross-cutting acceptance gates

Every work item must satisfy all applicable gates:

- `pixi run check` passes with Mojo 1.0.0 and the checked-in lockfile.
- New fallible behavior has rejection tests as well as success tests.
- Unicode behavior covers empty input, ASCII, combining marks, emoji, CJK, and
  endpoints inside multi-byte code points where relevant.
- Root exports are documented and backed by a compiling example.
- Generated Unicode data records its version, source URL, license, checksums,
  generator command, and deterministic regeneration check.
- Optimization does not change the public semantic contract.

## Work stream A — byte and semantic positions

### MOJI-001: validated byte ranges and safe UTF-8 slicing — complete locally

Deliverables:

- `ByteRange` with nonnegative, ordered, half-open endpoints;
- a normalization-closed representation that preserves those invariants even
  though Mojo 1.0 does not enforce private struct fields;
- UTF-8 code-point-boundary detection for a `StringSlice`;
- validation against a specific text value; and
- copying safe slices without exposing unchecked indexing.

Acceptance checks:

- reject negative, reversed, out-of-bounds, and code-point-splitting ranges;
- accept empty ranges at valid boundaries;
- document that code-point safety is not grapheme-cluster safety; and
- demonstrate the root API with CJK text.

### MOJI-002: explicit position types — complete

Prerequisite: MOJI-001.

Add nominal `ByteOffset`, `CodePointIndex`, `GraphemeIndex`, and
`DisplayColumn` values. Define construction, equality, ordering needs, and
conversion failure behavior without allowing raw integers to blur units.

The implemented types reject negative construction, normalize externally
reachable storage mutation, compare and order only within the same nominal
unit, and retain no text. Cross-unit conversion is intentionally absent in this
slice: MOJI-003, MOJI-004, and MOJI-010 will add explicit text-dependent
fallible conversions rather than implicit casts.

Acceptance checks:

- negative positions are unrepresentable or rejected;
- compile-time API fixtures show that unlike position units are not
  interchangeable; and
- no position type retains a borrowed string.

### MOJI-003: byte/code-point conversion

Prerequisite: MOJI-002.

Convert valid byte offsets to code-point indices and back. Reject byte offsets
inside a code point and indices beyond the final endpoint. Include round-trip
invariants for representative Unicode fixtures.

### MOJI-004: grapheme conversion and grapheme-safe slicing

Prerequisite: MOJI-003.

Build on Mojo's standard-library grapheme iterator. Convert byte and code-point
positions to grapheme indices, convert back, and provide explicitly named
grapheme-safe slicing. Cover combining sequences, emoji modifiers, regional
indicators, and zero-width-joiner sequences.

## Work stream B — transformed-to-source mappings

### MOJI-005: mapping segment contract

Prerequisite: MOJI-001.

Define a segment that associates one nonempty transformed byte range with one
nonempty source byte range. Decide and document expansion, contraction,
repeated-source, and reordered-source behavior. Validate both ranges against
their respective strings.

### MOJI-006: source map builder and queries

Prerequisite: MOJI-005.

Add a builder that enforces ordered, non-overlapping coverage of transformed
bytes. Query one transformed offset or range and return exact source ranges;
do not collapse discontiguous source ranges into a misleading bounding range.

Acceptance checks:

- one-to-one, one-to-many, and many-to-one transformations;
- CJK romanization-shaped fixtures such as `北京` to `beijing`;
- discontiguous highlighting remains discontiguous; and
- invalid gaps, overlaps, and UTF-8-splitting segments are rejected.

### MOJI-007: mapped text value

Prerequisite: MOJI-006.

Provide the smallest owned value that carries transformed text and its source
map together. Prove usage in standalone examples and integration fixtures for
the contracts expected by Yomi and Hibana without depending on either package.

## Work stream C — terminal width

### MOJI-008: width policy and Unicode data provenance

Prerequisite: none; may proceed alongside work stream B.

Specify control-character behavior, ambiguous-width policy, emoji sequence
handling, Unicode versioning, and table provenance. Review the existing
MojoTUI implementation as downstream evidence, but independently define
Moji's package contract and migration boundary.

### MOJI-009: scalar, grapheme, and text width

Prerequisite: MOJI-008 and MOJI-004.

Implement scalar classification and grapheme/text measurement from generated
tables. Keep ambiguous-width choice explicit. Add Unicode reference fixtures
and invariants that text width is the sum of its grapheme widths.

### MOJI-010: display-column conversion

Prerequisite: MOJI-009 and MOJI-002.

Convert grapheme boundaries to display columns and resolve display columns
back to boundaries under an explicit snap/reject policy. Cover zero-width and
double-width clusters and columns inside a wide grapheme.

## Work stream D — release proof

### MOJI-011: public API and downstream contract fixtures

Prerequisites: MOJI-007 and MOJI-010.

Reduce root exports to the reviewed v0.1 surface. Add examples for safe slicing,
source highlighting, and display-column layout. Add dependency-free fixtures
that model MojoTUI, Yomi, and Hibana call sites.

### MOJI-012: packaging and supported-target verification

Prerequisite: MOJI-011.

Run the complete suite on macOS ARM64, Linux x86-64, and Linux ARM64. Build the
Conda package, install it into a clean prefix, compile a consumer against the
installed `.mojoc`, and record any platform limitation in compatibility docs.

## v0.1 definition of done

The milestone is complete only when all twelve work items pass their acceptance
checks, every public symbol has a semantic-boundary and error contract, the
package installation smoke test passes on the declared matrix, and at least one
downstream integration fixture exercises both mapping and display width.
