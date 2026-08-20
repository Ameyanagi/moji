from moji import (
    ByteOffset,
    ByteRange,
    GraphemeIndex,
    byte_range_of_grapheme,
    count_graphemes,
    grapheme_index,
    grapheme_spans,
    slice_graphemes,
)
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _assert_single_cluster_round_trip(text: StringSlice, byte_length: Int) raises:
    assert_equal(count_graphemes(text), 1)
    assert_equal(grapheme_index(text, ByteOffset(0)).value(), 0)
    assert_equal(grapheme_index(text, ByteOffset(byte_length)).value(), 1)
    assert_true(
        byte_range_of_grapheme(text, GraphemeIndex(0)) == ByteRange(0, byte_length)
    )
    assert_equal(
        slice_graphemes(text, GraphemeIndex(0), GraphemeIndex(1)),
        String(text),
    )
    assert_equal(
        slice_graphemes(text, GraphemeIndex(1), GraphemeIndex(1)),
        "",
    )


def test_grapheme_round_trips_for_extended_cluster_fixtures() raises:
    _assert_single_cluster_round_trip("é", 3)
    _assert_single_cluster_round_trip("👨‍👩‍👧‍👦", 25)
    _assert_single_cluster_round_trip("🇯🇵", 8)
    _assert_single_cluster_round_trip("👍🏽", 8)


def test_grapheme_index_maps_all_boundaries_and_final_endpoint() raises:
    var text = String("a北🇯🇵")
    assert_equal(grapheme_index(text, ByteOffset(0)).value(), 0)
    assert_equal(grapheme_index(text, ByteOffset(1)).value(), 1)
    assert_equal(grapheme_index(text, ByteOffset(4)).value(), 2)
    assert_equal(grapheme_index(text, ByteOffset(12)).value(), 3)


def test_slice_graphemes_copies_half_open_cluster_ranges() raises:
    var text = String("aé🇯🇵z")
    assert_equal(
        slice_graphemes(text, GraphemeIndex(1), GraphemeIndex(3)),
        "é🇯🇵",
    )
    assert_equal(
        slice_graphemes(text, GraphemeIndex(2), GraphemeIndex(2)),
        "",
    )


def test_grapheme_index_rejects_offset_inside_cluster() raises:
    with assert_raises(
        contains=(
            "byte offset 1 is inside a grapheme cluster; nearest boundaries are 0 and 3"
        )
    ):
        _ = grapheme_index("é", ByteOffset(1))


def test_byte_range_of_grapheme_rejects_final_endpoint_as_element() raises:
    with assert_raises(contains="grapheme index 1 is outside grapheme cluster count 1"):
        _ = byte_range_of_grapheme("🇯🇵", GraphemeIndex(1))


def test_slice_graphemes_rejects_reversed_and_past_end_ranges() raises:
    with assert_raises(contains="grapheme slice start 2 must not exceed end 1"):
        _ = slice_graphemes("ab", GraphemeIndex(2), GraphemeIndex(1))
    with assert_raises(
        contains="grapheme slice end 3 is outside grapheme cluster count 2"
    ):
        _ = slice_graphemes("ab", GraphemeIndex(0), GraphemeIndex(3))


def test_grapheme_spans_report_borrowed_text_and_byte_ranges() raises:
    var text = String("a北👨‍👩‍👧‍👦é")
    var reconstructed = String()
    var span_index = 0
    for span in grapheme_spans(text):
        if span_index == 0:
            assert_true(span.byte_range() == ByteRange(0, 1))
            assert_equal(String(span.text()), "a")
        elif span_index == 1:
            assert_true(span.byte_range() == ByteRange(1, 4))
            assert_equal(String(span.text()), "北")
        elif span_index == 2:
            assert_true(span.byte_range() == ByteRange(4, 29))
            assert_equal(String(span.text()), "👨‍👩‍👧‍👦")
        elif span_index == 3:
            assert_true(span.byte_range() == ByteRange(29, 31))
            assert_equal(String(span.text()), "é")
        reconstructed += span.text()
        span_index += 1

    assert_equal(span_index, 4)
    assert_equal(reconstructed, text)


def test_grapheme_spans_empty_text_yields_no_spans() raises:
    var span_count = 0
    for _ in grapheme_spans(""):
        span_count += 1
    assert_equal(span_count, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
