# Data provenance

## Grapheme conformance fixture

The verbatim official corpus is vendored under
[`tests/fixtures/unicode-17.0.0/`](../tests/fixtures/unicode-17.0.0/).

| File | Source | SHA-256 |
| --- | --- | --- |
| `GraphemeBreakTest.txt` | [Unicode 17.0.0 UCD](https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakTest.txt) | `e2d134d2c52919bace503ebb6a551c1855fe1a1faec18478c78fff254a1793ec` |
| `LICENSE.txt` | [Unicode License V3](https://www.unicode.org/license.txt), retrieved 2026-09-05 | `e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96` |

The corpus contains 766 default grapheme-boundary cases and retains the Unicode
copyright header. The adjacent license is distributed with the unmodified
data. `scripts/check-grapheme-fixture.py` verifies both files offline before
the normal test suite; whitespace hooks exclude these byte-exact upstream files.
Test execution needs no network or generated source.

To update, retrieve the chosen version's official UCD file and license into a
new versioned fixture directory. Review the upstream changes and licensing,
update checksums and expected case count, then run the complete test suite.
Review every compiler exception described in
[compatibility](compatibility.md#grapheme-segmentation); never change expected
boundaries simply to make an upgrade pass.

## Unicode terminal-width tables

[`src/moji/_unicode_width_data.mojo`](../src/moji/_unicode_width_data.mojo) is a
generated lookup module pinned to Unicode 17.0.0. It is derived from these
canonical Unicode Character Database files:

| Upstream file | Canonical URL | SHA-256 |
| --- | --- | --- |
| `EastAsianWidth.txt` | `https://www.unicode.org/Public/17.0.0/ucd/EastAsianWidth.txt` | `ea7ce50f3444a050333448dffef1cadd9325af55cbb764b4a2280faf52170a33` |
| `DerivedGeneralCategory.txt` | `https://www.unicode.org/Public/17.0.0/ucd/extracted/DerivedGeneralCategory.txt` | `d62e5bab70ca74f099343f71224fa051cb1fdd61a1ab45c0488c44cfc0b6102e` |
| `emoji-data.txt` | `https://www.unicode.org/Public/17.0.0/ucd/emoji/emoji-data.txt` | `2cb2bb9455cda83e8481541ecf5b6dfda66a3bb89efa3fa7c5297eccf607b72b` |
| `PropList.txt` | `https://www.unicode.org/Public/17.0.0/ucd/PropList.txt` | `130dcddcaadaf071008bdfce1e7743e04fdfbc910886f017d9f9ac931d8c64dd` |

The generator is [`scripts/generate-unicode-width.py`](../scripts/generate-unicode-width.py).
From the repository root, regenerate with:

```sh
python3 scripts/generate-unicode-width.py
```

The generator verifies every downloaded source against its pinned SHA-256 digest
before parsing it. Given those exact source bytes, rerunning the generator
produces a byte-identical Mojo file; `python3 scripts/generate-unicode-width.py
--check` verifies that the committed output is current. Generation is a
development operation, so consumers of moji do not require Python or network
access.

The Unicode data files are distributed under the Unicode License. The generator
and generated tables were absorbed from mojotui; mojotui will migrate to consume
moji as the shared implementation.

## Terminal width policy

Widths are terminal display columns, not bytes, code points, or grapheme counts.

| Text class | Width policy |
| --- | --- |
| C0 and C1 controls, including DEL | 0 columns |
| Default-ignorables and zero-width combining scalars | 0 columns |
| East Asian Ambiguous scalars | 1 column with the default `NARROW` policy; 2 with opt-in `WIDE` |
| Fully-qualified emoji VS16 and ZWJ sequences | 2 columns per grapheme cluster |
| Unicode data version | Pinned to 17.0.0 |

Unicode width-policy or licensing changes require reviewing the upstream version,
canonical sources, checksums, generator output, and this documented behavior.
