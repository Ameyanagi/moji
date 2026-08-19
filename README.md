# Moji

> **Experimental — API not yet released.**

Unicode text, search, and layout primitives for Mojo.

## Scope

Moji fills application-layer gaps above Mojo's UTF-8 strings without duplicating standard-library grapheme support.

The first implementation milestone is intentionally narrow: implement terminal display width, validated byte ranges, safe slicing, index conversion, and transformed-to-source range mappings.
The project is independently installable and does not require any application
from the wider ecosystem.

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

The current scaffold includes only an internal smoke marker. Nothing is
re-exported as a stable public API yet.

## Repository map

- `src/moji/`: library or application source
- `tests/`: TestSuite unit, reference-value, and invariant tests
- `examples/`: small compilable usage programs
- `benchmarks/`: reproducible methodology and later benchmark programs
- `docs/`: architecture, design, compatibility, roadmap, and release policy
- `conda.recipe/`: local Rattler build recipe

See [the architecture](docs/architecture.md), [design principles](docs/design.md),
and [roadmap](docs/roadmap.md) before proposing a new dependency or feature.

## License

Licensed under either Apache-2.0 or MIT, at your option.
