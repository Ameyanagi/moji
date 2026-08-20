# v0.1 execution plan

This document turns the v0.1 roadmap into ordered, independently reviewable
work. Each work item should fit one focused pull request. Later items may begin
only when their listed prerequisites and acceptance checks are complete.

## Release outcome

Moji v0.1 is a standard-library-only package that lets callers:

1. name and validate UTF-8 byte ranges;
2. convert byte positions to and from code-point and grapheme positions, and
   independently convert grapheme-boundary bytes to and from display columns;
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
- Constructors and every public observation reject externally corrupted
  storage; no coordinate or range is silently normalized or clamped.

## Work stream A — byte and semantic positions

### MOJI-001: validated byte ranges and safe UTF-8 slicing — complete locally

Deliverables:

- `ByteRange` with nonnegative, ordered, half-open endpoints;
- a temporary normalization-based representation that is explicitly blocked
  from release by MOJI-002R;
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
conversion failure behavior without implicit unit mixing. Calling `value()`
explicitly erases the nominal unit and makes the caller responsible for tracking
what the resulting `Int` means.

The implemented types reject negative construction but currently clamp
externally reachable negative storage to zero. That temporary behavior does not
satisfy the release contract. Cross-unit conversion is intentionally absent in
this slice: MOJI-003, MOJI-004, and MOJI-010 will add explicit text-dependent
fallible conversions rather than implicit casts.

Acceptance checks:

- negative positions are unrepresentable or rejected;
- compile-time API fixtures show that unlike position units are not implicitly
  interchangeable in arguments, equality, or ordering;
- no position type retains a borrowed string.

### MOJI-002R: remove silent normalization — mandatory before release

Prerequisites: MOJI-001 and MOJI-002.

Replace ByteRange and position normalization with storage revalidation on every
public observation. Invalid mutation raises instead of becoming zero, empty,
reordered, or saturated. If pinned Mojo comparison traits cannot raise, remove
their conformance and add checked same-unit equality/ordering methods. Lock the
same rule into MappingSegment and MappedText before those types land.

Acceptance checks:

- mutate every reachable ByteRange and position field to negative, reversed, or
  overflow-shaped state and prove every public observation rejects it;
- prove valid empty ranges and valid endpoints retain their exact values;
- keep compile-fail unit-mixing fixtures without relying on infallible trait
  comparison; and
- block MOJI-003, MOJI-005, both packaged sub-gates, and release until green.

### MOJI-003: byte/code-point conversion

Prerequisite: MOJI-002R.

Convert valid byte offsets to code-point indices and back. Reject byte offsets
inside a code point and indices beyond the final endpoint. Convert one valid
non-final code-point index directly to its exact non-empty ByteRange; reject the
final endpoint because it does not identify a scalar. Include round-trip
invariants for representative Unicode fixtures.

### MOJI-004: grapheme conversion and grapheme-safe slicing

Prerequisite: MOJI-003.

Build on Mojo's standard-library grapheme iterator. Convert byte and code-point
positions to grapheme indices, convert back, and provide explicitly named
grapheme-safe slicing. Cover combining sequences, emoji modifiers, regional
indicators, and zero-width-joiner sequences.

## Work stream B — transformed-to-source mappings

### MOJI-005: mapping segment contract

Prerequisite: MOJI-002R.

Define a segment that associates one nonempty transformed byte range with one
nonempty source byte range. Decide and document expansion, contraction,
repeated-source, and reordered-source behavior. Validate both ranges against
their respective strings.

### MOJI-006: source map builder and queries

Prerequisite: MOJI-005.

Add a builder that enforces ordered, non-overlapping coverage of transformed
bytes. Batch-project an immutable collection/view of transformed ranges,
validating the aggregate and all non-empty members once before output. Accept an
empty collection and arbitrary member order; globally sort and merge only
overlap/touch. Never collapse a source gap into a bounding range or return a
partial result after an error.

Acceptance checks:

- one-to-one, one-to-many, and many-to-one transformations;
- CJK romanization-shaped fixtures such as `北京` to `beijing`;
- discontiguous highlighting remains discontiguous;
- multiple scalar-position ranges merge globally without caller-side mapping
  logic; and
- invalid gaps, overlaps, and UTF-8-splitting segments are rejected.

### MOJI-007: mapped text value

Prerequisite: MOJI-006.

Provide the smallest owned value that carries transformed text and its source
map together. Prove usage in standalone examples and integration fixtures for
the contracts expected by Yomi and Hibana without depending on either package.
Expose `text() raises -> String` as a revalidated owned snapshot; a borrowed view
waits for a separate compiled lifetime design.

## Work stream C — terminal width

### MOJI-008: width policy and Unicode data provenance

Prerequisite: MOJI-002R; may proceed alongside work stream B.

Specify control-character behavior, ambiguous-width policy, emoji sequence
handling, Unicode versioning, and table provenance. Review the existing
MojoTUI implementation as downstream evidence, but independently define
Moji's package contract and migration boundary.

### MOJI-009: scalar, grapheme, and text width

Prerequisite: MOJI-008 and MOJI-004.

Implement internal scalar/cluster classification and public one-line
`text_width()` from generated tables. Keep ambiguous-width choice explicit. Add
Unicode reference fixtures and invariants that text width is the sum of its
grapheme widths. Do not export a separate `grapheme_width()` unless downstream
evidence demonstrates semantics not served by `text_width()`.

### MOJI-010: display-column conversion

Prerequisite: MOJI-009 and MOJI-002R.

Convert grapheme-boundary byte offsets to display columns and resolve display
columns back to bytes. Rejection is the default when a column has no exact byte
boundary inside a wide grapheme or has multiple boundaries across zero-width
graphemes. Named BEFORE chooses the earliest resolving byte boundary and AFTER
the latest. Cover zero-width and double-width clusters and both ambiguity forms.

## Work stream D — release proof

### MOJI-011S: packaged search-coordinate and mapping gate

Prerequisites: MOJI-003 and MOJI-007.

Review only the coordinate/mapping root exports. Add examples for safe slicing
and source highlighting plus dependency-free Yomi/Hibana/Yuragi-shaped fixtures.
Build the package, install it into a clean prefix, and compile a consumer against
the installed `.mojoc`. Display width is not an entry criterion.

### MOJI-011W: packaged display-width gate

Prerequisites: MOJI-004 and MOJI-010.

Review only the display root exports. Add a display-column example and a
dependency-free MojoTUI-shaped fixture. Build/install/compile the same clean
package boundary. Mapping is not an entry criterion.

### MOJI-012: packaging and supported-target verification

Prerequisites: MOJI-011S and MOJI-011W.

Run the complete suite on macOS ARM64, Linux x86-64, and Linux ARM64. Build the
Conda package, install it into a clean prefix, compile a consumer against the
installed `.mojoc`, and record any platform limitation in compatibility docs.

## v0.1 definition of done

The milestone is complete only when every mandatory work item and both packaged
sub-gates pass, every public symbol has a semantic-boundary and error contract,
and the package installation smoke test passes on the declared matrix. Mapping
and display width have separate downstream fixtures; no artificial combined
consumer is required.
