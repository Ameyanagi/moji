# Text indexing benchmarks and profiles

`bench_text_index.mojo` measures index construction, 1,024 repeated coordinate
lookups, one terminal-width pass, and transformed-to-source matcher mapping. Its
generated fixtures are deterministic: 6,144 mixed Unicode scalars (ASCII, CJK,
a combining sequence, and an emoji ZWJ sequence), 6,144 ASCII scalars including
controls, realistic `北京 -> beijing` expansion, and deliberately reordered
discontiguous mappings. Each case has three warmups and 31 samples; reported
p50/p95 values are nearest-rank samples 16/30. Checksums compare indexed and
one-off semantics and prevent dead-code removal.

Build and run the optimized executable through the checked-in workflow:

```sh
pixi run benchmark-text
```

Apple M4, macOS 26.5.1 (25F80), Mojo 1.0.0, `-O3`, measured 2026-08-22:

| case | p50 | p95 |
| --- | ---: | ---: |
| mixed-Unicode index build | 101 µs | 102 µs |
| mixed-Unicode one-off, 1,024 lookups | 46.344 ms | 48.632 ms |
| mixed-Unicode indexed, 1,024 lookups | 34 µs | 54 µs |
| mixed-Unicode `text_width` | 510 µs | 513 µs |
| ASCII index build | 67 µs | 68 µs |
| ASCII one-off, 1,024 lookups | 30.668 ms | 32.487 ms |
| ASCII indexed, 1,024 lookups | 4 µs | 6 µs |
| ASCII `text_width` | 116 µs | 117 µs |
| mapped CJK expansion, 28 positions × 512 calls | 72 µs | 75 µs |
| mapped CJK expansion, full range × 512 calls | 65 µs | 66 µs |
| mapped monotonic sparse, 96 positions × 64 calls | 54 µs | 55 µs |
| mapped reordered, 24 positions × 512 calls | 327 µs | 329 µs |
| mapped reordered, 48 positions × 256 calls | 374 µs | 375 µs |
| mapped reordered, 63 positions × 128 calls | 290 µs | 291 µs |
| mapped reordered, 64 positions × 128 calls | 287 µs | 287 µs |
| mapped reordered, 96 positions × 64 calls | 218 µs | 220 µs |
| mapped reordered range, 96 scalars × 64 calls | 208 µs | 209 µs |
| mapped reordered, 192 positions × 16 calls | 115 µs | 119 µs |
| mapped reordered, 384 positions × 4 calls | 62 µs | 62 µs |
| mapped bridge collapse, 191 positions × 16 calls | 121 µs | 121 µs |

These figures are development evidence, not portable guarantees. Construction
is intentionally reported separately: an index only makes sense when its text
will receive repeated queries.

## Sampling profiler

`profile_text.mojo` provides long-running `legacy`, `indexed`, `width`,
`mapped-realistic`, `mapped-adversarial`, and `mapped-adversarial-large`
workloads. On macOS, compile with line tables and sample a live process:

```sh
pixi run profile-text-build
.pixi/profile-text legacy &
sample $! 10 -file .pixi/moji-legacy.sample.txt
```

For transformed-source mapping, substitute one of the mapped modes. The
realistic workload selects 28 consecutive transformed positions across four
expanded CJK phrases. The adversarial workloads select 96 or 384 one-byte source
ranges in alternating high/low encounter order, with one-byte gaps that prevent
union merging.

In the Apple M4 legacy trace above, the active main thread had 8,366 samples:
4,093 were attributed directly to the `byte_offset_of` loop and 4,270 to the
inlined reverse conversion loop in `main`. This is the repeated UTF-8 rescan
that motivated `TextIndex`; allocation or terminal-width tables were not the
dominant cost in that workload. The `width` workload remains a grapheme and
Unicode-table traversal, while indexed scalar lookups are integer table or
ASCII-identity operations.

The first indexed profile exposed a redundant boundary predicate before the
authoritative endpoint-table search. After folding validation into the binary
search, a second 4,153-sample active-thread trace contained no
`is_codepoint_boundary` frames; invalid offsets still take the same detailed
error path after a failed exact table lookup.

The mapped profiles explain the intentional two-path union. In the 3,964-sample
realistic trace, matcher validation and mapping accounted for 2,175 samples and
allocation for 501; monotonic expansion stays on the final-range fast path. In
the initial pre-sort 96-position trace, 3,617 of 4,216 samples landed in
exact-union mapping.
Before the large fallback changed, 3,806 of 3,926 active samples in the
384-position trace landed in the quadratic union scan. In the final thresholded
trace, heap sifting accounted for 2,761 of 3,855 active samples and allocation
for 52. Sorting is now the expected dominant large-query work, while its bound
is O(k log k) instead of O(k²).
Once mappings move backwards in source order, preserving transformed encounter
order requires either the general scan or auxiliary indexing. Fewer than 64
selected mappings retain the simple O(k²) scan; 64 or more switch to an
O(k log k) heap-sort/sweep with O(k) temporary storage. Ordinary monotonic
mappings never sort and remain amortized O(k). Components from either path are
emitted by earliest contributor, not by source offset.

The 63/64 cells establish the conservative crossover. In adjacent forced-scan
and thresholded builds, the 64-position batch changed from 336 to 287 µs for 128
calls, while the 63-position control changed from 328 to 290 µs as machine
frequency shifted. The larger raw changes were 337 to 218 µs at 96 positions,
310 to 115 µs at 192, and 310 to 62 µs at 384. Normalizing by the 63-position
control gives approximate gains of 3%, 27%, 58%, and 77%, respectively. The
adversarial cells remain separate from ordinary CJK latency claims.

The forced-scan comparison used the same worktree and commands as the table:
`_SORTED_UNION_THRESHOLD` in `src/moji/text_index.mojo` was temporarily changed
from 64 to 1,000,000, `pixi run benchmark-text-build` rebuilt the executable,
and the five reordered cells ran immediately before restoring 64 and rebuilding.
The final p50 values per query are 2.27 µs at 63 positions, 2.24 µs at 64,
3.41 µs at 96, 7.19 µs at 192, and 15.50 µs at 384.

No SIMD path is used here. Variable-length UTF-8 decoding, boundary validation,
grapheme segmentation, and width-table branches are not regular lane-wise
kernels. Replacing repeated scans with O(1)/O(log n) indexing produced the
measured gain without unsafe byte access or architecture-specific behavior.
