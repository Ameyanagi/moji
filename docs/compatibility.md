# Compatibility

## Toolchain

Development currently pins Mojo `1.0.0`. Precompiled `.mojoc` files are tied to
the exact compiler version that produced them, so both the Pixi environment and
Conda recipe pin the compiler. Compiler upgrades are explicit compatibility
events and require the full locked test suite.

## Grapheme segmentation

All public grapheme operations, including `GraphemeBoundaryIndex`, delegate to
the **Mojo 1.0.0 standard library**. This compiler pin is the segmentation
version contract. The independent terminal-width tables use Unicode 17.0.0;
that does not imply the compiler implements every Unicode 17.0.0 boundary.
Moji applies no locale, editor, or terminal-specific segmentation tailoring.

The mandatory `pixi run --locked test` / `check` gate verifies the vendored
official Unicode **17.0.0 GraphemeBreakTest** and license checksums, then runs
all **766 cases** plus empty text through the public streaming and indexed
grapheme APIs. It checks cluster counts, spans, all exact byte boundaries,
every interior-byte rejection, and every half-open cluster slice. Of the
official cases, 757 match Unicode 17.0.0 directly. These nine observed compiler
compatibility differences are accepted explicitly to preserve existing APIs:

| Official fixture line | Pinned compiler behavior | Unicode 17.0.0 behavior |
| --- | --- | --- |
| 771 | Joins `2701 200D 2701` into one cluster | Breaks before the final U+2701 |
| 785–786 | Splits Myanmar conjuncts at some consonants | Joins them under GB9c |
| 787, 789–790 | Splits Balinese conjuncts at some consonants | Joins them under GB9c |
| 788, 791–792 | Splits Khmer conjuncts at some consonants | Joins them under GB9c |

[`grapheme-exceptions-mojo-1.0.0.txt`](../tests/fixtures/grapheme-exceptions-mojo-1.0.0.txt)
records each exact source line, observed UTF-8 boundary list, and rationale.
These are documented upstream version mismatches, **not** claims that the
Unicode defaults are incorrect or deliberate linguistic tailoring. No case is
skipped: each exception must match its recorded boundaries, then the full
public-API checks run against that profile. A new mismatch, changed exception,
unused exception, or exception that now matches Unicode fails the test.

Compiler upgrades must run this gate on all supported platforms and review
every boundary change. Remove obsolete exceptions after reviewing their
consumer impact; document any newly accepted mismatch individually. Never
replace the corpus expectation wholesale with compiler output. Upgrading the
official corpus also requires its provenance/checksum update and a fresh
exception review. See [data provenance](data-provenance.md#grapheme-conformance-fixture).

## Platforms

| Platform | Status |
| --- | --- |
| macOS ARM64 | CI target |
| Linux x86-64 | CI target |
| Linux ARM64 | CI target |
| Windows/WSL | Not yet supported or tested |
| GPU | Not supported unless explicitly listed in the roadmap |

The `0.x` series is experimental and does not promise source compatibility
between minor releases. Each release names the exact compiler used to build it.
