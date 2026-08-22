"""Long-running compiled workloads for sampling Moji text hot paths."""

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
from std.sys import argv


comptime _LEGACY_ROUNDS = 5_000
comptime _INDEXED_ROUNDS = 3_200_000
comptime _WIDTH_ROUNDS = 20_000
comptime _QUERY_COUNT = 64
comptime _MAPPED_REALISTIC_ROUNDS = 40_000_000
comptime _MAPPED_ADVERSARIAL_ROUNDS = 1_200_000
comptime _MAPPED_ADVERSARIAL_LARGE_ROUNDS = 400_000


def _unicode_text() -> String:
    var text = String()
    for _ in range(512):
        text += "a北京é👨‍👩‍👧‍👦"
    return text^


def _queries(count: Int) -> List[Int]:
    var queries = List[Int](capacity=_QUERY_COUNT)
    for index in range(_QUERY_COUNT):
        queries.append((index * 811 + 17) % (count + 1))
    return queries^


def _legacy_scan() raises:
    var text = _unicode_text()
    var count = len(text.codepoints())
    var queries = _queries(count)
    var offsets = List[ByteOffset](capacity=len(queries))
    for query in queries:
        offsets.append(byte_offset_of(text, CodePointIndex(query)))

    var checksum = 0
    for _ in range(_LEGACY_ROUNDS):
        for index in range(len(queries)):
            checksum += byte_offset_of(text, CodePointIndex(queries[index])).value()
            checksum += code_point_index(text, offsets[index]).value()
    keep(checksum)


def _indexed_lookup() raises:
    var text = _unicode_text()
    var index = TextIndex(text)
    var queries = _queries(index.code_point_count())
    var offsets = List[ByteOffset](capacity=len(queries))
    for query in queries:
        offsets.append(index.byte_offset(CodePointIndex(query)))

    var checksum = 0
    for _ in range(_INDEXED_ROUNDS):
        for query_index in range(len(queries)):
            checksum += index.byte_offset(CodePointIndex(queries[query_index])).value()
            checksum += index.code_point_index(offsets[query_index]).value()
    keep(checksum)


def _width_scan():
    var text = _unicode_text()
    var checksum = 0
    for _ in range(_WIDTH_ROUNDS):
        checksum += text_width(text)
    keep(checksum)


def _mapped_realistic() raises:
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

    var checksum = 0
    for _ in range(_MAPPED_REALISTIC_ROUNDS):
        var ranges = mapped.source_ranges_of_code_points(positions)
        checksum += len(ranges) + ranges[0].start() + 3 * ranges[0].end()
    keep(checksum)


def _mapped_adversarial(range_count: Int, rounds: Int) raises:
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

    var checksum = 0
    for _ in range(rounds):
        var ranges = mapped.source_ranges_of_code_points(positions)
        checksum += len(ranges)
        for index in range(len(ranges)):
            checksum += (index + 1) * (
                ranges[index].start() + 3 * ranges[index].end()
            )
    keep(checksum)


def main() raises:
    var arguments = argv()
    if len(arguments) == 2 and String(arguments[1]) == "legacy":
        _legacy_scan()
        return
    if len(arguments) == 2 and String(arguments[1]) == "indexed":
        _indexed_lookup()
        return
    if len(arguments) == 2 and String(arguments[1]) == "width":
        _width_scan()
        return
    if len(arguments) == 2 and String(arguments[1]) == "mapped-realistic":
        _mapped_realistic()
        return
    if len(arguments) == 2 and String(arguments[1]) == "mapped-adversarial":
        _mapped_adversarial(96, _MAPPED_ADVERSARIAL_ROUNDS)
        return
    if len(arguments) == 2 and String(arguments[1]) == "mapped-adversarial-large":
        _mapped_adversarial(384, _MAPPED_ADVERSARIAL_LARGE_ROUNDS)
        return
    raise Error(
        "usage: profile_text "
        "<legacy|indexed|width|mapped-realistic|mapped-adversarial|"
        "mapped-adversarial-large>"
    )
