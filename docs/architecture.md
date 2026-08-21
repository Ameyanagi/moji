# Architecture

Moji owns Unicode application text views, terminal width, safe indexing, and lossless transformed-to-source mappings.

## Dependency boundary

Allowed ecosystem dependencies: Mojo standard library only.
Expected downstream consumers: MojoTUI, Hibana, Yomi, Yuragi, and other text-heavy Mojo applications.

Dependencies point from applications and higher-level packages toward smaller
foundations. This repository must never import a downstream consumer. New
dependencies require a documented need and must not force unrelated users to
install an application, renderer, language layer, or scientific stack.

## Layers

Planned implementation areas: width, boundary, index, slice, mapping, text-view, and property adapters built on Mojo 1.0 grapheme iteration.

The first implemented layer is `byte_range.mojo`. It owns half-open byte ranges,
UTF-8 code-point-boundary validation, and safe slicing. It deliberately does
not claim grapheme safety; semantic index conversions will build above it.

`ByteRange` validates nonnegative, ordered endpoints at construction and then
serves non-raising reads directly from its underscore-prefixed storage. Mojo 1.0
does not enforce field privacy, so direct mutation of that storage is out of
contract. Callers doing unusual low-level mutation can use the explicit raising
`validate()` method as a checkpoint. Construction from two trusted `ByteOffset`
values validates their ordering without erasing their unit at the call site.

Boundary classification accepts `StringSlice`, whose text has already entered
Mojo's UTF-8 string model. It does not validate arbitrary byte buffers. Moji
guards out-of-bounds offsets, then delegates classification to the pinned
standard library's `StringSlice.is_codepoint_boundary()`. This keeps Unicode
storage semantics in the standard library while giving applications a total
predicate that returns `False` for invalid offsets.

`position.mojo` defines nominal byte, code-point, grapheme, and display-column
coordinates. They retain only an `Int`, never a borrowed string. Construction
rejects negative input, after which non-raising value reads and comparisons trust
the stored invariant. Direct mutation of underscore-prefixed storage is out of
contract, with one explicit raising `validate()` checkpoint available per type.
Equality and ordering accept only the same nominal unit. Cross-unit conversion is
deliberately absent until the relevant text and width contracts can validate it.
Calling `value()` is an explicit unit-erasure escape hatch; code that extracts an
`Int` assumes responsibility for preserving its coordinate meaning.

The package root exports only the small documented public surface. Algorithms,
generated tables, platform details, and backend implementations remain in
their owning modules. Generic Mojo-native buffers, spans, strings, and
collections are preferred over an ecosystem-specific universal container.

## Data flow

Input validation occurs at the public boundary. Internal layers operate on
explicit typed values, produce deterministic outputs for deterministic inputs,
and report invalid state rather than silently replacing it with a default.
I/O, clocks, randomness, terminal queries, filesystem access, and accelerator
selection stay at explicit effect or backend boundaries.
