# Moji

> **Experimental — API not yet released.**

Unicode text, search, and layout primitives for Mojo.

## Scope

Moji fills application-layer gaps above Mojo's UTF-8 strings without duplicating
standard-library grapheme support. It provides terminal display width, validated
byte ranges, safe slicing, explicit index conversion, and lossless source-range
mappings.

The project is independently installable and does not require any application
from the wider ecosystem.

## Install

For a Pixi project, add the hosted channel and install the Conda package:

```sh
pixi project channel add https://ameyanagi.github.io/mojo-channel
pixi add mojo-moji
```

Alternatively, work from a source checkout:

```sh
git clone https://github.com/Ameyanagi/moji.git
cd moji
pixi install --locked
pixi run mojo run -I src your_file.mojo
```

## Quickstart

```mojo
from moji import text_width


def main():
    print("width:", text_width("北京 👨‍👩‍👧‍👦"))
```

Run it: save this as `demo.mojo` and run
`pixi run mojo run -I src demo.mojo` from a clone.

## Real-task example

Truncate a filename without splitting a grapheme cluster:

```mojo
from moji import (
    ByteOffset,
    ByteRange,
    DisplayColumn,
    byte_offset_at_column,
    slice_text,
    text_width,
)


def truncate_filename(text: StringSlice, columns: Int) raises -> String:
    if text_width(text) <= columns:
        return String(text)
    var ellipsis = String("…")
    var content_columns = max(columns - text_width(ellipsis), 0)
    var end = byte_offset_at_column(
        text,
        DisplayColumn(content_columns),
    )
    return String(
        slice_text(text, ByteRange(ByteOffset(0), end)),
        ellipsis,
    )


def main() raises:
    var label = String("北京 👨‍👩‍👧‍👦")
    print("width:", text_width(label))

    var filename = String("2026-北京旅行-家族👨‍👩‍👧‍👦-notes.txt")
    print(truncate_filename(filename, 20))

    print(slice_text("a北京b", ByteRange(1, 7)))
```

`text_width()` measures terminal columns per extended grapheme cluster.
`byte_offset_at_column()` returns a grapheme boundary. The default snap is
`ColumnSnap.FLOOR` (a column inside a wide cluster snaps to its left edge);
`ColumnSnap.REJECT` raises instead of snapping. `ByteRange` remains half-open,
and `slice_text()` rejects ranges outside the text or inside UTF-8 code points.

For repeated scalar-coordinate lookups, build an owned index once:

```mojo
from moji import ByteOffset, CodePointIndex, TextIndex


def main() raises:
    var index = TextIndex("a北京b")
    print(index.byte_offset(CodePointIndex(3)))
    print(index.code_point_index(ByteOffset(7)))
```

`TextIndex` preserves the one-off conversion contracts while avoiding a UTF-8
rescan per lookup. Non-ASCII text uses an endpoint table; ASCII uses identity
byte/code-point coordinates without retaining that table. `MappedText` adds one
validated source `ByteRange` per transformed scalar for exact expansion,
contraction, reordered, and discontiguous source highlighting. See
`examples/index_and_map.mojo` for the complete mapping shape. Matcher-produced
scalar positions map directly through `MappedText.source_ranges_of_code_points()`.

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

The Mojo import is `moji`. The Conda package is `mojo-moji` on the hosted
channel above. Source lives under `src/moji/`, whose `__init__.mojo` defines the
package boundary.

The experimental root API exports nominal byte, code-point, grapheme, and
display-column coordinates plus range, conversion, grapheme, slicing, and width
operations. These names are tested but remain subject to change until the first
release.

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
