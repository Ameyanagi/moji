# Reference architecture

This document fixes the architectural boundary for Moji v0.1 before the
grapheme, mapping, and display-width layers are implemented. It is based on
primary upstream implementations, but it does not import their source, data,
or public API shapes. Moji remains a small, Mojo-native application text
library rather than a Unicode database or byte-string package.

The research clones are external working material under
`/Users/ryuichi/dev/reference-libraries/moji/`. They are not repository
inputs, build dependencies, test dependencies, or distribution contents.

## Goals

- Make byte, code-point, grapheme, and display-column coordinates explicit
  and non-interchangeable.
- Provide checked conversions and slices over valid Mojo UTF-8 strings.
- Preserve exact byte-range provenance when text is transformed for search or
  display.
- Measure one line of terminal text under an explicit ambiguous-width policy.
- Delegate Unicode semantics already supplied by the pinned Mojo standard
  library.
- Keep the root import surface small enough to review as one coherent v0.1
  contract.

## Non-goals

- A general byte-string type, lossy UTF-8 decoder, or invalid-UTF-8 recovery
  policy.
- A second implementation of Unicode normalization, case conversion, word
  boundaries, or grapheme segmentation.
- A rope, piece table, editor buffer, or persistent text index.
- Locale-specific transliteration, pronunciation, or CJK reading data; those
  belong in Yomi.
- Fuzzy matching or ranking; those belong in Hibana.
- Terminal line breaking, bidi layout, font shaping, cursor I/O, or terminal
  capability detection.
- Silent coordinate clamping, unit coercion, or guessed behavior for a column
  inside a wide grapheme.

## Primary reference matrix

The references were shallow-cloned at depth one on 2026-08-20. Commit IDs are
recorded so future design reviews do not silently compare against different
upstream behavior.

| Reference | Exact revision and license | Relevant public contracts | Moji conclusion |
| --- | --- | --- | --- |
| [`unicode-segmentation`](https://github.com/unicode-rs/unicode-segmentation/tree/091fb72c5e9cd1f06f4d3df1315ed7011a201084) | `091fb72c5e9cd1f06f4d3df1315ed7011a201084`; MIT OR Apache-2.0; crate 1.13.3; Unicode 17.0.0 | `graphemes(true)` yields extended grapheme slices; `grapheme_indices(true)` pairs each slice with its byte start; `GraphemeCursor` supports chunked/random access; conformance tests derive from the official GraphemeBreakTest data. | Adopt extended grapheme clusters and byte-offset-based conversion tests. Delegate segmentation to Mojo's `StringSlice.graphemes()` instead of porting tables or the cursor abstraction. |
| [`unicode-width`](https://github.com/unicode-rs/unicode-width/tree/832f7ca447375ff969f850dab9362a0c2ce1eefb) | `832f7ca447375ff969f850dab9362a0c2ce1eefb`; MIT OR Apache-2.0; crate 0.2.2; Unicode 17.0.0 | Separate scalar and string width APIs; explicit narrow versus CJK handling for ambiguous characters; scalar controls can have no width; sequence width is not necessarily the sum of scalar widths; exports its Unicode version. | Adopt an explicit ambiguous-width policy, grapheme/sequence-aware measurement, and visible Unicode-data provenance. Do not present width as font or terminal truth, and do not use a language-labeled boolean policy. |
| [`bstr`](https://github.com/BurntSushi/bstr/tree/134195be38c7c9a4887980fd0f6f8bae042dd91e) | `134195be38c7c9a4887980fd0f6f8bae042dd91e`; MIT OR Apache-2.0; crate 1.13.1 | `char_indices()` returns explicit `(start, end, scalar)` byte coordinates; `grapheme_indices()` returns `(start, end, slice)`; invalid UTF-8 can be replaced while source byte indices remain exact; `utf8_chunks` exposes valid/invalid runs. | Adopt explicit half-open start/end ranges and exact source coordinates. Reject byte-string and replacement-decoding semantics for v0.1 because Moji's public input is valid Mojo text. |

Ropey was considered but not cloned. Its chunked rope storage, char-indexed
editing, and tree metrics solve an editor-buffer problem that is explicitly
outside Moji v0.1. If profiling later justifies a persistent index, that work
must begin with a separate architecture decision rather than entering through
the conversion API by accident.

### Reference cautions

- The references are evidence, not specifications. Unicode Standard Annexes
  and pinned Unicode data remain the normative inputs for behavior Moji owns.
- `bstr`'s checked-in segmentation fixtures currently identify Unicode 14.0.0,
  so they are not a Unicode 17 conformance authority for Moji.
- `unicode-width` explicitly warns that computed width can differ from actual
  rendering. Moji therefore calls this a deterministic terminal layout policy,
  not a measure of pixels or fonts.
- No source or generated table from these projects may be copied without a
  separate provenance and license review.

## Adopted and rejected ideas

### Adopted

- Half-open byte ranges: `[start, end)` composes with slicing and represents an
  empty range at every valid boundary.
- Distinct nominal coordinate types for bytes, code points, graphemes, and
  display columns.
- Extended grapheme clusters for user-perceived indexing.
- Explicit byte starts and ends for all mapping segments, even when a helper
  could infer an end from the next segment.
- String/cluster-aware terminal width, because emoji and control sequences can
  invalidate scalar-width addition.
- A named ambiguous-width policy with narrow and wide variants.
- Exact Unicode version and input provenance for any generated width data.
- Linear, correctness-first conversions before adding indexes or caches.

### Rejected for v0.1

- A chunk cursor modeled on `GraphemeCursor`; Moji accepts contiguous
  `StringSlice` input.
- Byte-string methods and replacement decoding modeled on `bstr`; invalid
  UTF-8 is not a state reachable through the public text contract.
- A `cjk: Bool` width parameter. East Asian Ambiguous handling is a terminal
  policy, not a reliable statement about the language of a string.
- Scalar-width summation as the text-width algorithm.
- One integer type shared by all coordinate systems.
- An eager `TextView` index in v0.1. It adds ownership, invalidation, and memory
  policy before benchmarks demonstrate a need.
- Root exports for internal scanners, table lookup functions, or source-map
  construction machinery.

## Unicode-data ownership and standard-library delegation

Moji follows this decision order for every Unicode behavior:

1. If the pinned Mojo standard library supplies the semantic operation, use
   it and wrap it only to add Moji's typed coordinate or error contract.
2. If the standard library lacks the operation and v0.1 requires it, Moji may
   own a generated table only with a pinned Unicode version, official source
   URL, checksum, license note, deterministic generator, and regeneration
   instructions.
3. If neither condition holds, defer the feature rather than approximating it.

Under Mojo 1.0.0 stable this means:

- UTF-8 scalar-boundary classification delegates to
  `StringSlice.is_codepoint_boundary()`.
- Code-point iteration delegates to `StringSlice` iteration.
- Extended grapheme segmentation delegates to `StringSlice.graphemes()`.
- Moji owns the typed counting, conversion, slicing, and validation around
  those operations.
- Moji may own terminal-width policy and generated width tables because the
  standard library does not currently provide the required terminal contract.
- Moji does not own normalization or character-property tables merely to make
  another API more convenient.

Generated width data, if introduced by MOJI-008, must be committed as a
deterministic artifact so package consumers need only Mojo. Generation tooling
may be separate from runtime code, but the distributed library must not require
Python, Rust, C, or network access.

## Coordinate and mapping layers

The layers form a one-way semantic ladder. A numeric value never crosses a
layer without a named checked conversion.

```text
storage bytes       ByteOffset, ByteRange
       |             valid UTF-8 boundary checks
       v
Unicode scalars     CodePointIndex
       |             standard-library iteration
       v
user text units     GraphemeIndex
       |             standard-library grapheme segmentation
       v
terminal layout     DisplayColumn + WidthPolicy

transformed bytes   MappingSegment[]   source bytes
       \____________ SourceMap _____________/
                         |
                      MappedText
```

### Storage coordinates

`ByteRange` remains half-open. Construction and every public observation
revalidate its reachable endpoint storage and raise if the start is negative,
the end precedes the start, or the represented length overflows. No accessor
clamps, reorders, saturates, or converts invalid storage to an empty range. A
checked text operation additionally requires both endpoints to be UTF-8
code-point boundaries.

The current experimental start/length-hint implementation normalizes corrupted
storage. That is temporary scaffolding, not this architecture's contract;
MOJI-002R must replace it before any release.

Empty ranges are valid only at a code-point boundary. In particular, an empty
range inside a multibyte scalar is rejected.

### Scalar and grapheme coordinates

Conversions count boundaries from the start of the supplied `StringSlice`.
The end boundary is a valid index in every coordinate system. A conversion
raises when its input is out of range or is not a boundary in the source
coordinate system.

For valid Mojo UTF-8 text, `CodePointIndex` counts Unicode scalar values and is
the nominal form of Hibana's documented scalar position. It does not count
bytes, graphemes, UTF-16 code units, or display cells.

Initial conversion complexity is linear in the traversed prefix. This is a
documented contract, not an invitation to hide a cache in a value type. A
persistent index can be considered only after representative benchmarks show
that repeated scans dominate downstream work.

`codepoint_to_byte_range(text, index)` names the one Unicode scalar at `index`
as a checked non-empty `ByteRange`. It rejects the final code-point boundary,
which is valid for `codepoint_to_byte()` but does not identify a scalar. This is
the minimal bridge from Hibana's scalar positions to mapping queries; callers do
not erase the unit, add one, or assemble byte endpoints themselves.

### Display coordinates

Width is calculated per extended grapheme cluster and accumulated into a
`DisplayColumn`. `WidthPolicy` names whether East Asian Ambiguous characters
use narrow or wide cells. It does not infer policy from text language.

The v0.1 width functions measure one logical line. They raise on line breaks
and hard terminal controls rather than assigning them a fictitious cell width;
combining marks, variation selectors, joiners, and other components handled by
the cluster width algorithm are not classified as standalone hard controls.

`byte_to_column()` accepts only a grapheme boundary and measures the prefix
under the supplied `WidthPolicy`. This is the single forward bridge into display
coordinates; callers do not slice and copy a prefix merely to call
`text_width()`.

Reverse mapping is unique only when exactly one grapheme boundary occupies the
requested display column. A column inside a multi-cell grapheme has no exact
boundary, while a zero-width grapheme run can place several byte boundaries at
the same column. `ColumnResolution.REJECT` raises in either non-unique case.
`BEFORE` returns the earliest resolving byte boundary and `AFTER` returns the
latest. These names cover both wide-cell interiors and zero-width boundary runs;
there is no silent snapping or boolean resolution mode.

### Transformation mappings

A `MappingSegment` connects one non-empty transformed `ByteRange` to one
non-empty source `ByteRange`. Both ranges must end on code-point boundaries in
their respective texts.

A finalized map enforces these invariants:

- transformed ranges are sorted, non-overlapping, and cover the entire
  transformed text without gaps;
- source ranges may repeat, contract, expand, or occur out of source order;
- an empty transformed text has no segments;
- an empty query-range collection returns an empty result;
- every member query is non-empty and checked against the transformed text
  before projection; members may arrive in any order;
- intersecting any part of an indivisible transformed segment projects that
  segment's full source range;
- batch projection validates the mapped aggregate and every query once before
  producing output; any error raises without a partial result; and
- all projected results are globally sorted by source position and merge only
  overlapping or touching ranges, never a source gap.

These rules cover one-to-one transliteration, expansion, contraction,
reordering, and discontiguous source highlighting without claiming a
character-to-character correspondence that does not exist.

## Ownership, errors, and mutation

### Ownership

- Coordinate and range values own only small integers and have value semantics.
- Conversion functions borrow a `StringSlice` for the duration of a call and
  return detached coordinate values.
- A public slicing helper returns an owned `String`; it does not manufacture a
  long-lived borrow.
- Final mapped text owns copies of the source and transformed strings together
  with the map validated against them. A map therefore cannot silently outlive
  or detach from the texts that define its byte coordinates.
- `MappedText.text()` revalidates and returns an owned copy of the transformed
  text. The copy is the correctness-first v0.1 bridge to Hibana; a borrowed view
  requires a separate compiled lifetime design.
- Mutable internal segment storage is never returned directly. Inspection, if
  required, returns detached values.

### Errors

- Boundary predicates are total and return `False` for negative or
  out-of-bounds offsets.
- Slicing, coordinate conversion, map construction, map queries, and width
  measurement raise on an invalid contract.
- No public operation silently clamps an offset, guesses a unit, replaces
  invalid text, or snaps a display column unless the caller supplied a named
  resolution policy.
- Error messages identify the rejected coordinate and the relevant text
  length where practical, but message wording is not a v0.1 stability promise.

### Mutation under Mojo 1.0

Mojo 1.0 does not enforce the field privacy needed to make every nominal value
opaque. Moji therefore has one rule: constructors and every public observation
revalidate reachable storage and raise on invalid state. They never normalize,
clamp, reorder, saturate, or guess a replacement value.

This includes `value`, range endpoints and length, containment, slicing,
conversion, mapping-segment inspection, `MappedText.text`, and map projection.
Relational aggregates revalidate the complete aggregate against their owned
texts once per public operation. Public APIs never expose mutable aggregate
storage.

If `Equatable` or ordering trait signatures cannot raise under the pinned Mojo
compiler, the affected nominal types do not conform to those traits. They expose
checked same-unit methods such as `equals()` and `less_than()` instead. It is
safer to omit operator syntax than to compare corrupted state silently.

MOJI-002R replaces the current normalization implementation and adds direct
mutation tests for ByteRange and every position type before MOJI-003 or MOJI-005
lands. Mapping types must use the checked rule from their first implementation.
No Moji release or downstream package gate may waive this issue.

## Minimal root API sketch

This is a design sketch for issue review, not a promise that unimplemented
symbols already exist. Types appear at the package root only when their issue
delivers tested behavior; builders and table internals remain in submodules.

```mojo
from moji import (
    ByteOffset,
    CodePointIndex,
    GraphemeIndex,
    DisplayColumn,
    ByteRange,
    MappingSegment,
    MappedText,
    WidthPolicy,
    ColumnResolution,
    is_utf8_boundary,
    validate_text_range,
    slice_text,
    byte_to_codepoint,
    codepoint_to_byte,
    codepoint_to_byte_range,
    byte_to_grapheme,
    grapheme_to_byte,
    text_width,
    byte_to_column,
    column_to_byte,
)
```

`ColumnResolution` enters the root only if the tested `BEFORE` and `AFTER`
policies ship. Otherwise `column_to_byte` exposes only rejecting behavior and
the type stays internal or absent.

The intended shapes are deliberately functional:

```text
byte_to_codepoint(text, byte) raises -> CodePointIndex
codepoint_to_byte(text, index) raises -> ByteOffset
codepoint_to_byte_range(text, index) raises -> ByteRange
byte_to_grapheme(text, byte) raises -> GraphemeIndex
grapheme_to_byte(text, index) raises -> ByteOffset
text_width(text, policy) raises -> DisplayColumn
byte_to_column(text, byte, policy) raises -> DisplayColumn
column_to_byte(text, column, policy, resolution) raises -> ByteOffset
MappedText(source, transformed, segments) raises
MappedText.text() raises -> String
MappedText.source_ranges(output_ranges) raises -> List[ByteRange]
```

The exact immutable Mojo-native collection/view type for `output_ranges` is
fixed by a compiled ownership prototype in MOJI-006. The batch semantics above
are fixed regardless of that container spelling. A one-range convenience
overload waits for demonstrated use; callers can pass a one-element collection.

There is no generic integer overload, implicit unit conversion, global width
mode, mutable singleton, or application-specific representation on the root
surface.

## Test consequences

Every issue adds tests at the layer it introduces rather than relying only on
an end-to-end downstream test.

### Coordinates and boundaries

- Empty text, start/end boundaries, empty ranges, and out-of-range values.
- Every byte position within representative two-, three-, and four-byte
  scalars, including rejection of an empty range inside a scalar.
- Round trips for every valid boundary:
  byte -> code point -> byte and byte -> grapheme -> byte.
- Exact one-scalar byte ranges for every valid code-point index, including
  rejection of the final boundary as a scalar.
- Combining marks, regional indicators, emoji modifiers, keycaps, variation
  selectors, ZWJ sequences, CRLF, Hangul Jamo, and CJK text.
- Adversarial external mutation of every reachable nominal field.
- Compile-fail fixtures showing that different coordinate units cannot be
  substituted.

### Grapheme conformance

Moji should use a compact checked-in adversarial fixture initially and run it
through the standard-library grapheme API. A complete official
`GraphemeBreakTest.txt` fixture is appropriate only after its Unicode version,
source URL, checksum, derivation, and license are recorded. The fixture must
not become a copied implementation table.

### Mappings

- One-to-one, expansion, contraction, repeated-source, reordered-source, and
  discontiguous projection cases.
- Exact full-segment projection from a partial intersecting output query.
- Empty batches, one-element batches, unordered query ranges, duplicate ranges,
  and globally exact merging across multiple discontiguous matches.
- Rejection of gaps, overlaps, zero-length segments, invalid boundaries, and
  incomplete transformed coverage.
- Mutation after successful construction followed by every public observation,
  proving revalidation cannot be bypassed.
- Owned-lifetime tests demonstrating that caller strings and input segment
  lists may change or leave scope without changing a finalized `MappedText`.
- `text()` snapshot tests proving that it is byte-identical, detached, and
  revalidates aggregate mutation before copying.

### Width

- Official Unicode-versioned property cases and emoji sequence cases used by
  the generator contract.
- Narrow and wide ambiguous-policy expectations on the same input.
- Zero-width combining behavior and multi-code-point emoji behavior.
- Rejection of newlines and hard controls in one-line measurement.
- Display-column round trips at grapheme boundaries and explicit behavior for
  a column inside a two-cell grapheme.
- Reject/before/after behavior for both a wide-cell interior and several byte
  boundaries sharing one column across zero-width graphemes.
- Explicit terminal caveat tests should check deterministic policy results,
  not make claims about a particular emulator or font.

### Package boundary

Each delivered public type or function is exercised both from the package root
and by `conda.recipe/test_package.mojo`. Internal modules must not be required
for the primary workflow.

## Benchmark consequences

Benchmarks publish methodology and raw observations, not superiority claims.
They record CPU, OS, Mojo version, compiler flags, dataset, warmup, iteration
count, and metric.

Initial workloads should include:

- byte/code-point/grapheme conversions near the start, middle, and end of long
  ASCII, CJK, decomposed, and emoji-heavy strings;
- repeated conversions over the same text, to provide evidence for or against
  a future persistent index;
- map construction and projection for one-to-one, expansion, contraction, and
  highly discontiguous matches;
- one-line width measurement for ASCII, ambiguous-width text, CJK, combining
  sequences, and emoji ZWJ sequences.

The v0.1 expectation for coordinate conversion and width measurement is linear
scanning. A later index must demonstrate a representative improvement after
including construction time and memory cost.

## Executable issue ordering

This supersedes the issue-ordering details in
[`execution-plan.md`](execution-plan.md).

1. Complete mandatory **MOJI-002R** first, replacing temporary normalization in
   ByteRange and positions with checked mutation behavior. No downstream gate
   may use the current semantics.
2. Start three independent lanes from that corrected foundation: **MOJI-003**
   for byte/code-point and single-scalar range conversion, **MOJI-005** for the
   mapping-segment contract, and **MOJI-008** for width policy/provenance.
3. Complete **MOJI-004** after MOJI-003 by delegating segmentation to
   `StringSlice.graphemes()` and adding grapheme conversions, slicing, and
   adversarial fixtures.
4. Complete **MOJI-006** and then **MOJI-007** after MOJI-005, enforcing
   gap-free transformed coverage, validate-once batch projection, full
   revalidation, and an owned mapped-text lifetime plus `text()` snapshot.
5. Complete **MOJI-009** only after both MOJI-004 and MOJI-008; implement
   grapheme-aware one-line width accumulated into `DisplayColumn`.
6. Complete **MOJI-010** after MOJI-009, adding checked byte-to-column and
   rejecting column-to-byte conversion first. Add named before/after resolution
   only with wide and zero-width ambiguity tests.
7. Complete packaged search gate **MOJI-011S** after MOJI-003 and MOJI-007,
   independent of width. It proves root imports, clean-prefix installation, and
   Moji scalar-to-byte/Yomi mapping/Hibana position/Yuragi highlight fixtures.
8. Complete packaged display gate **MOJI-011W** after MOJI-004 and MOJI-010,
   independent of mapping. It proves the minimal width root, clean-prefix
   installation, and MojoTUI-shaped fixtures.
9. Finish **MOJI-012** after both gates with the full v0.1 surface, generated-data
   provenance, supported targets, and clean-prefix installation checks.

This ordering keeps search-coordinate/mapping readiness independent of display
width, and keeps the byte-only mapping lane independent of grapheme work. No
issue adds an eager text index, invalid-UTF-8 layer, or application-specific API.

## Decision triggers after v0.1

The following require new evidence and a separate design record:

- a persistent `TextView` or coordinate index, after repeated-scan benchmarks;
- chunked or rope-backed segmentation, after a real consumer supplies a
  non-contiguous storage requirement;
- lossy or raw-byte processing, after a consumer demonstrates why a separate
  byte-oriented package is insufficient;
- terminal capability probing or line layout, which may be better owned by
  MojoTUI;
- additional Unicode tables, only when the pinned standard library cannot
  supply the required semantics.
