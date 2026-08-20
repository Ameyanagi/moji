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
from moji import ByteRange, slice_text


def main() raises:
    var text = String("北京 notes")
    var city = slice_text(text, ByteRange(0, 6))
    print(city)
```

`ByteRange` is half-open: its start is inclusive and its end is exclusive.
Construction validates the ordering of its offsets. `slice_text()` additionally
validates the range against the supplied text and requires both endpoints to be
UTF-8 code-point boundaries. Read the endpoints with `start()` and `end()`;
underscore-prefixed storage is not API. Grapheme-aware indexing is a separate
planned API.

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

The experimental root API currently exports `ByteRange`, `is_utf8_boundary`,
`validate_text_range`, and `slice_text`. These names are tested but remain
subject to change until the first release.

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
