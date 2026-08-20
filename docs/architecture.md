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

Mojo 1.0 does not enforce private struct fields. `ByteRange` therefore uses
underscore-prefixed storage by convention and a normalization-closed
representation: every possible pair of underlying `Int` values produces
nonnegative, ordered, representable semantic endpoints through `start()` and
`end()`. Public behavior never trusts the raw storage values.

Boundary classification accepts `StringSlice`, whose text has already entered
Mojo's UTF-8 string model. It does not validate arbitrary byte buffers. Moji
guards out-of-bounds offsets, then delegates classification to the pinned
standard library's `StringSlice.is_codepoint_boundary()`. This keeps Unicode
storage semantics in the standard library while giving applications a total
predicate that returns `False` for invalid offsets.

`position.mojo` defines nominal byte, code-point, grapheme, and display-column
coordinates. They retain only an `Int`, never a borrowed string. Construction
rejects negative input, and their normalization-closed storage keeps semantic
values nonnegative even after externally reachable field mutation. Equality and
ordering accept only the same nominal unit. Cross-unit conversion is deliberately
absent until the relevant text and width contracts can validate it.

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
