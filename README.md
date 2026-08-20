# Moji

> **Experimental — API not yet released.**

Unicode text, search, and layout primitives for Mojo.

## Scope

Moji fills application-layer gaps above Mojo's UTF-8 strings without duplicating standard-library grapheme support.

The first implementation milestone is intentionally narrow: implement terminal display width, validated byte ranges, safe slicing, index conversion, and transformed-to-source range mappings.
The project is independently installable and does not require any application
from the wider ecosystem.

## Quick start

Moji's first public slice makes UTF-8 byte indexing explicit and rejects slices
that split a multi-byte code point:

```mojo
from moji import ByteOffset, ByteRange, slice_text


def main() raises:
    var text = String("北京 notes")
    var city_start = ByteOffset(0)
    var city_end = ByteOffset(6)
    var city = slice_text(text, ByteRange(city_start, city_end))
    print(city)
```

`ByteRange` is half-open: its start is inclusive and its end is exclusive.
Construction from either integer endpoints or `ByteOffset` values validates
their ordering. `slice_text()` additionally validates the range against the
supplied text and requires both endpoints to be UTF-8 code-point boundaries.
Read the endpoints with `start()` and `end()`; underscore-prefixed storage is
not API. Construction establishes storage invariants and reads trust them
thereafter. Call `validate()` for an explicit checkpoint after unusual low-level
mutation. Grapheme-aware indexing is a separate planned API.

Moji also distinguishes `ByteOffset`, `CodePointIndex`, `GraphemeIndex`, and
`DisplayColumn` as nominal nonnegative coordinate values. Equality and ordering
operate only within the same unit. These values retain no text, and Moji does
not implicitly convert between them: later text-dependent conversion functions
will require the source text and report invalid boundaries or indices.
Calling `value()` explicitly erases the unit, so callers comparing extracted
integers are responsible for keeping their coordinate meanings aligned. Their
constructors reject negative values, reads trust the established invariant, and
`validate()` provides an explicit checkpoint.

## Development

Install [Pixi](https://pixi.sh/), then run:

```sh
pixi install --locked
pixi run check
pixi run example
```

The exact stable Mojo compiler and all development dependencies are captured in
`pixi.lock`. Runtime and library code is Mojo-first and pure Mojo wherever
practical. Build-time data generation may use another language when justified,
but generated outputs must be deterministic, checksum-pinned, licensed, and
documented.

## Package

The Mojo import is `moji`. The eventual Conda distribution is
`mojo-moji`. Source lives under `src/moji/`, whose
`__init__.mojo` defines the package boundary.

The experimental root API currently exports the four coordinate types plus
`ByteRange`, `is_utf8_boundary`, `validate_text_range`, and `slice_text`. These
names are tested but remain subject to change until the first release.

## Repository map

- `src/moji/`: library or application source
- `tests/`: TestSuite unit, reference-value, and invariant tests
- `examples/`: small compilable usage programs
- `benchmarks/`: reproducible methodology and later benchmark programs
- `docs/`: architecture, design, compatibility, roadmap, and release policy
- `conda.recipe/`: local Rattler build recipe

See [the architecture](docs/architecture.md), [design principles](docs/design.md),
[roadmap](docs/roadmap.md), and [v0.1 execution plan](docs/execution-plan.md)
before proposing a new dependency or feature.

## License

Licensed under either Apache-2.0 or MIT, at your option.
