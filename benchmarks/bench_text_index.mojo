"""Repeated UTF-8 conversion and terminal-width benchmark."""

from moji import (
    ByteOffset,
    ByteRange,
    CodePointIndex,
    MappedText,
    TextIndex,
    byte_offset_of,
    code_point_index,
    text_width,
)
from std.benchmark import keep
from std.collections import List
from std.time import perf_counter_ns


comptime _SAMPLES = 31
comptime _WARMUPS = 3
comptime _QUERY_COUNT = 64
comptime _BATCHES = 8
comptime _REALISTIC_MAPPING_CALLS = 512
comptime _MAPPING_CALLS = 64


def _unicode_text() -> String:
    var text = String()
    for _ in range(512):
        text += "a北京é👨‍👩‍👧‍👦"
    return text^


def _ascii_text() -> String:
    var text = String()
    for index in range(6_144):
        if index % 97 == 0:
            text += "\t"
        else:
            text += chr(0x20 + (index * 17) % 95)
    return text^


def _queries(count: Int) -> List[Int]:
    var queries = List[Int](capacity=_QUERY_COUNT)
    for index in range(_QUERY_COUNT):
        queries.append((index * 811 + 17) % (count + 1))
    return queries^


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


def _legacy_batch(
    text: StringSlice,
    queries: List[Int],
    offsets: List[ByteOffset],
) raises -> Int:
    var checksum = 0
    for _ in range(_BATCHES):
        for index in range(len(queries)):
            checksum += byte_offset_of(text, CodePointIndex(queries[index])).value()
            checksum += code_point_index(text, offsets[index]).value()
    keep(checksum)
    return checksum


def _indexed_batch(
    index: TextIndex,
    queries: List[Int],
    offsets: List[ByteOffset],
) raises -> Int:
    var checksum = 0
    for _ in range(_BATCHES):
        for query_index in range(len(queries)):
            checksum += index.byte_offset(CodePointIndex(queries[query_index])).value()
            checksum += index.code_point_index(offsets[query_index]).value()
    keep(checksum)
    return checksum


def _measure_lookups(label: StringSlice, text: String) raises:
    var index = TextIndex(text)
    var queries = _queries(index.code_point_count())
    var offsets = List[ByteOffset](capacity=len(queries))
    for query in queries:
        offsets.append(index.byte_offset(CodePointIndex(query)))

    var expected = _legacy_batch(text, queries, offsets)
    if _indexed_batch(index, queries, offsets) != expected:
        raise Error("indexed conversion checksum differs from one-off conversion")
    for _ in range(_WARMUPS):
        _ = _legacy_batch(text, queries, offsets)
        _ = _indexed_batch(index, queries, offsets)

    var legacy_timings = List[Int](capacity=_SAMPLES)
    var indexed_timings = List[Int](capacity=_SAMPLES)
    for _ in range(_SAMPLES):
        var started = perf_counter_ns()
        if _legacy_batch(text, queries, offsets) != expected:
            raise Error("legacy checksum changed")
        legacy_timings.append(perf_counter_ns() - started)

        started = perf_counter_ns()
        if _indexed_batch(index, queries, offsets) != expected:
            raise Error("indexed checksum changed")
        indexed_timings.append(perf_counter_ns() - started)

    _sort_timings(legacy_timings)
    _sort_timings(indexed_timings)
    _print_timings(String(label, "_legacy_1024_lookups"), legacy_timings, expected)
    _print_timings(String(label, "_indexed_1024_lookups"), indexed_timings, expected)


def _measure_build(label: StringSlice, text: String) raises:
    var expected = TextIndex(text).code_point_count()
    var timings = List[Int](capacity=_SAMPLES)
    for _ in range(_WARMUPS):
        keep(TextIndex(text).code_point_count())
    for _ in range(_SAMPLES):
        var started = perf_counter_ns()
        var count = TextIndex(text).code_point_count()
        timings.append(perf_counter_ns() - started)
        if count != expected:
            raise Error("index build count changed")
        keep(count)
    _sort_timings(timings)
    _print_timings(String(label, "_index_build"), timings, expected)


def _measure_width(label: StringSlice, text: String) raises:
    var expected = text_width(text)
    var timings = List[Int](capacity=_SAMPLES)
    for _ in range(_WARMUPS):
        keep(text_width(text))
    for _ in range(_SAMPLES):
        var started = perf_counter_ns()
        var width = text_width(text)
        timings.append(perf_counter_ns() - started)
        if width != expected:
            raise Error("width checksum changed")
        keep(width)
    _sort_timings(timings)
    _print_timings(String(label, "_text_width"), timings, expected)


def _mapped_batch(
    mapped: MappedText, positions: List[Int], calls: Int
) raises -> Int:
    var checksum = 0
    for _ in range(calls):
        var ranges = mapped.source_ranges_of_code_points(positions)
        checksum += len(ranges)
        for index in range(len(ranges)):
            checksum += (index + 1) * (
                ranges[index].start() + 3 * ranges[index].end()
            )
    keep(checksum)
    return checksum


def _mapped_range_batch(
    mapped: MappedText, transformed_range: ByteRange, calls: Int
) raises -> Int:
    var checksum = 0
    for _ in range(calls):
        var ranges = mapped.source_ranges(transformed_range)
        checksum += len(ranges)
        for index in range(len(ranges)):
            checksum += (index + 1) * (
                ranges[index].start() + 3 * ranges[index].end()
            )
    keep(checksum)
    return checksum


def _measure_mapped_positions(
    label: StringSlice,
    mapped: MappedText,
    positions: List[Int],
    calls: Int,
) raises:
    var expected = _mapped_batch(mapped, positions, calls)
    for _ in range(_WARMUPS):
        if _mapped_batch(mapped, positions, calls) != expected:
            raise Error(String(label, " checksum changed during warmup"))
    var timings = List[Int](capacity=_SAMPLES)
    for _ in range(_SAMPLES):
        var started = perf_counter_ns()
        if _mapped_batch(mapped, positions, calls) != expected:
            raise Error(String(label, " checksum changed"))
        timings.append(perf_counter_ns() - started)
    _sort_timings(timings)
    _print_timings(label, timings, expected)


def _measure_mapped_range(
    label: StringSlice,
    mapped: MappedText,
    transformed_range: ByteRange,
    calls: Int,
) raises:
    var expected = _mapped_range_batch(mapped, transformed_range, calls)
    for _ in range(_WARMUPS):
        if _mapped_range_batch(mapped, transformed_range, calls) != expected:
            raise Error(String(label, " checksum changed during warmup"))
    var timings = List[Int](capacity=_SAMPLES)
    for _ in range(_SAMPLES):
        var started = perf_counter_ns()
        if _mapped_range_batch(mapped, transformed_range, calls) != expected:
            raise Error(String(label, " checksum changed"))
        timings.append(perf_counter_ns() - started)
    _sort_timings(timings)
    _print_timings(label, timings, expected)


def _measure_realistic_mapped_text() raises:
    # Four consecutive expanded `北京 -> beijing` phrases model the short,
    # monotonic matcher spans used by ordinary CJK candidate highlighting.
    var source = String()
    var transformed = String()
    var origins = List[ByteRange](capacity=7 * 256)
    for phrase_index in range(256):
        source += "北京"
        transformed += "beijing"
        var source_start = phrase_index * 6
        for _ in range(3):
            origins.append(ByteRange(source_start, source_start + 3))
        for _ in range(4):
            origins.append(ByteRange(source_start + 3, source_start + 6))
    var mapped = MappedText(source, transformed, origins)
    var positions = List[Int](capacity=28)
    for position in range(7 * 64, 7 * 68):
        positions.append(position)

    _measure_mapped_positions(
        "mapped_cjk_expansion_28_positions_512_calls",
        mapped,
        positions,
        _REALISTIC_MAPPING_CALLS,
    )
    _measure_mapped_range(
        "mapped_cjk_expansion_full_range_512_calls",
        mapped,
        ByteRange(7 * 64, 7 * 68),
        _REALISTIC_MAPPING_CALLS,
    )


def _measure_adversarial_mapped_text(range_count: Int, calls: Int) raises:
    # Alternating high/low source slots force encounter order away from byte
    # order. One-byte gaps retain every exact union component.
    var source = String()
    var transformed = String()
    var origins = List[ByteRange](capacity=range_count)
    var positions = List[Int](capacity=range_count)
    for _ in range(range_count):
        source += "a_"
        transformed += "x"
    for index in range(range_count):
        var source_slot = index // 2
        if index % 2 == 0:
            source_slot = range_count - 1 - source_slot
        origins.append(ByteRange(2 * source_slot, 2 * source_slot + 1))
        positions.append(index)
    var mapped = MappedText(source, transformed, origins)

    _measure_mapped_positions(
        String(
            "mapped_reordered_",
            range_count,
            "_positions_",
            calls,
            "_calls",
        ),
        mapped,
        positions,
        calls,
    )
    if range_count == 96:
        _measure_mapped_range(
            "mapped_reordered_range_96_scalars_64_calls",
            mapped,
            ByteRange(0, range_count),
            calls,
        )


def _measure_monotonic_sparse_mapped_text() raises:
    comptime RANGE_COUNT = 96
    var source = String()
    var transformed = String()
    var origins = List[ByteRange](capacity=RANGE_COUNT)
    var positions = List[Int](capacity=RANGE_COUNT)
    for index in range(RANGE_COUNT):
        source += "a_"
        transformed += "x"
        origins.append(ByteRange(2 * index, 2 * index + 1))
        positions.append(index)
    var mapped = MappedText(source, transformed, origins)
    _measure_mapped_positions(
        "mapped_monotonic_sparse_96_positions_64_calls",
        mapped,
        positions,
        _MAPPING_CALLS,
    )


def _measure_bridge_collapse_mapped_text() raises:
    comptime COMPONENT_COUNT = 96
    var source = String()
    for _ in range(2 * COMPONENT_COUNT):
        source += "a"
    var transformed = String()
    var origins = List[ByteRange](capacity=2 * COMPONENT_COUNT - 1)
    var positions = List[Int](capacity=2 * COMPONENT_COUNT - 1)
    for component in range(COMPONENT_COUNT):
        transformed += "x"
        origins.append(ByteRange(2 * component, 2 * component + 1))
        positions.append(len(positions))
    for bridge in range(COMPONENT_COUNT - 1):
        transformed += "x"
        origins.append(ByteRange(2 * bridge + 1, 2 * bridge + 2))
        positions.append(len(positions))
    var mapped = MappedText(source, transformed, origins)
    _measure_mapped_positions(
        "mapped_bridge_collapse_191_positions_16_calls",
        mapped,
        positions,
        16,
    )


def main() raises:
    print(
        "BENCH_HEADER moji text-index mojo=1.0.0 -O3 samples=31 warmup=3 ",
        "statistic=nearest-rank-p50-p95 queries=64 batches=8",
        sep="",
    )
    var unicode = _unicode_text()
    var ascii = _ascii_text()
    _measure_build("unicode", unicode)
    _measure_lookups("unicode", unicode)
    _measure_width("unicode", unicode)
    _measure_build("ascii", ascii)
    _measure_lookups("ascii", ascii)
    _measure_width("ascii", ascii)
    _measure_realistic_mapped_text()
    _measure_monotonic_sparse_mapped_text()
    _measure_adversarial_mapped_text(24, 512)
    _measure_adversarial_mapped_text(48, 256)
    _measure_adversarial_mapped_text(63, 128)
    _measure_adversarial_mapped_text(64, 128)
    _measure_adversarial_mapped_text(96, 64)
    _measure_adversarial_mapped_text(192, 16)
    _measure_adversarial_mapped_text(384, 4)
    _measure_bridge_collapse_mapped_text()
