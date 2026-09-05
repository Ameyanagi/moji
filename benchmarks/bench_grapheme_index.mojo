"""Deterministic repeated cursor conversions; build cost reported separately."""

from moji import (
    ByteOffset,
    GraphemeBoundaryIndex,
    GraphemeIndex,
    byte_range_of_grapheme,
    count_graphemes,
    grapheme_index,
)
from std.benchmark import keep
from std.collections import List
from std.time import perf_counter_ns

comptime _SAMPLES = 31
comptime _WARMUPS = 3
comptime _QUERIES = 64
comptime _BATCHES = 8


def _text(unit: StringSlice, repetitions: Int) -> String:
    var result = String()
    for _ in range(repetitions):
        result += unit
    return result^


def _sort_timings(mut values: List[Int]):
    for index in range(1, len(values)):
        var value = values[index]
        var destination = index
        while destination > 0 and values[destination - 1] > value:
            values[destination] = values[destination - 1]
            destination -= 1
        values[destination] = value


def _print_timings(label: StringSlice, timings: List[Int], checksum: Int):
    print(
        "case=",
        label,
        " samples=31 statistic=nearest-rank",
        " p50_ns=",
        timings[15],
        " p95_ns=",
        timings[29],
        " checksum=",
        checksum,
        sep="",
    )


def _reference(
    text: StringSlice, queries: List[Int], offsets: List[ByteOffset]
) raises -> Int:
    var checksum = 0
    for _ in range(_BATCHES):
        for query in range(_QUERIES):
            checksum += byte_range_of_grapheme(
                text, GraphemeIndex(queries[query])
            ).start()
            checksum += grapheme_index(text, offsets[query]).value()
    keep(checksum)
    return checksum


def _indexed(
    index: GraphemeBoundaryIndex, queries: List[Int], offsets: List[ByteOffset]
) raises -> Int:
    var checksum = 0
    for _ in range(_BATCHES):
        for query in range(_QUERIES):
            checksum += index.byte_offset(GraphemeIndex(queries[query])).value()
            checksum += index.grapheme_index(offsets[query]).value()
    keep(checksum)
    return checksum


def _measure(label: StringSlice, text: String) raises:
    var index = GraphemeBoundaryIndex(text)
    var queries = List[Int]()
    var offsets = List[ByteOffset]()
    for query in range(_QUERIES):
        var position = (query * 811 + 17) % index.grapheme_count()
        queries.append(position)
        offsets.append(index.byte_offset(GraphemeIndex(position)))
    var expected = _reference(text, queries, offsets)
    var builds = List[Int]()
    var references = List[Int]()
    var indexed = List[Int]()
    for sample in range(-_WARMUPS, _SAMPLES):
        var started = perf_counter_ns()
        var fresh = GraphemeBoundaryIndex(text)
        # Consume the entire object so allocation and construction stay observable.
        keep(fresh)
        var elapsed_build = perf_counter_ns() - started
        started = perf_counter_ns()
        var actual_reference = _reference(text, queries, offsets)
        var elapsed_reference = perf_counter_ns() - started
        started = perf_counter_ns()
        var actual_indexed = _indexed(index, queries, offsets)
        var elapsed_indexed = perf_counter_ns() - started
        if actual_reference != expected or actual_indexed != expected:
            raise Error("grapheme coordinate checksums differ")
        if sample >= 0:
            builds.append(elapsed_build)
            references.append(elapsed_reference)
            indexed.append(elapsed_indexed)
    _sort_timings(builds)
    _sort_timings(references)
    _sort_timings(indexed)
    print(
        "dataset=",
        label,
        " bytes=",
        text.byte_length(),
        " clusters=",
        count_graphemes(text),
        sep="",
    )
    _print_timings(String(label, "_build"), builds, index.grapheme_count())
    _print_timings(String(label, "_reference_1024_lookups"), references, expected)
    _print_timings(String(label, "_indexed_1024_lookups"), indexed, expected)


def main() raises:
    print(
        "BENCH_HEADER moji grapheme-index mojo=1.0.0 -O3 samples=31 warmups=3"
        " queries=64 batches=8"
    )
    _measure("cjk_small", _text("北京東京", 4))
    _measure("emoji_small", _text("é🇯🇵👨‍👩‍👧‍👦👍🏽", 4))
    _measure("cjk_long", _text("北京東京", 1024))
    _measure("emoji_long", _text("é🇯🇵👨‍👩‍👧‍👦👍🏽", 1024))
