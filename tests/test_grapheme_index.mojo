from moji import (
    ByteOffset,
    ByteRange,
    GraphemeBoundaryIndex,
    GraphemeIndex,
    byte_range_of_grapheme,
    count_graphemes,
    grapheme_index,
    grapheme_spans,
    slice_graphemes,
)
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _compare_reference(text: StringSlice) raises:
    var index = GraphemeBoundaryIndex(String(text))
    index.validate()
    assert_equal(index.byte_length(), text.byte_length())
    assert_equal(index.grapheme_count(), count_graphemes(text))
    assert_equal(String(index.text()), String(text))
    var boundary = 0
    for span in grapheme_spans(text):
        assert_equal(
            index.byte_offset(GraphemeIndex(boundary)).value(),
            span.byte_range().start(),
        )
        assert_true(
            index.byte_range(GraphemeIndex(boundary), GraphemeIndex(boundary + 1))
            == byte_range_of_grapheme(text, GraphemeIndex(boundary))
        )
        boundary += 1
    assert_equal(index.byte_offset(GraphemeIndex(boundary)).value(), text.byte_length())
    for offset in range(text.byte_length() + 1):
        var expected = -1
        var message = String()
        try:
            expected = grapheme_index(text, ByteOffset(offset)).value()
        except error:
            message = String(error)
        if expected >= 0:
            assert_equal(index.grapheme_index(ByteOffset(offset)).value(), expected)
        else:
            with assert_raises(contains=message):
                _ = index.grapheme_index(ByteOffset(offset))
    for start in range(index.grapheme_count() + 1):
        for end in range(start, index.grapheme_count() + 1):
            assert_equal(
                String(index.slice(GraphemeIndex(start), GraphemeIndex(end))),
                slice_graphemes(text, GraphemeIndex(start), GraphemeIndex(end)),
            )


def test_queries_match_streaming_reference_at_every_byte_and_cluster_range() raises:
    _compare_reference("")
    _compare_reference("ascii\r\n\x00text")
    _compare_reference("北京東京")
    _compare_reference("aé🇯🇵👨‍👩‍👧‍👦👍🏽z")
    _compare_reference("🇯🇵🇺🇸🇬é́")


def test_ownership_copy_and_borrowed_views() raises:
    var source = String("é北京")
    var index = GraphemeBoundaryIndex(source)
    source = "edited"
    assert_equal(source, "edited")
    assert_equal(String(index.text()), "é北京")
    var copied = index.copy()
    assert_true(index == copied)
    assert_true(index != GraphemeBoundaryIndex("other"))
    assert_equal(String(copied.slice(GraphemeIndex(1), GraphemeIndex(3))), "北京")
    var transferred = String("🇯🇵")
    var moved = GraphemeBoundaryIndex(transferred^)
    assert_equal(moved.grapheme_count(), 1)


def test_invalid_indices_and_ranges_are_rejected() raises:
    var index = GraphemeBoundaryIndex("é")
    with assert_raises(contains="grapheme index 2 is past final endpoint 1"):
        _ = index.byte_offset(GraphemeIndex(2))
    with assert_raises(contains="byte offset 4 is outside text byte length 3"):
        _ = index.grapheme_index(ByteOffset(4))
    with assert_raises(contains="grapheme range start 1 must not exceed end 0"):
        _ = index.byte_range(GraphemeIndex(1), GraphemeIndex(0))
    with assert_raises(contains="grapheme index 2 is past final endpoint 1"):
        _ = index.slice(GraphemeIndex(0), GraphemeIndex(2))
    var empty = GraphemeBoundaryIndex("")
    assert_true(empty.byte_range(GraphemeIndex(0), GraphemeIndex(0)) == ByteRange(0, 0))
    with assert_raises(contains="grapheme index 1 is past final endpoint 0"):
        _ = empty.byte_offset(GraphemeIndex(1))


def test_explicit_validate_detects_damaged_boundaries() raises:
    var index = GraphemeBoundaryIndex("éb")
    index._byte_offsets[1] = 1
    with assert_raises(contains="grapheme boundary 1 has byte offset 1; expected 3"):
        index.validate()
    index = GraphemeBoundaryIndex("ab")
    _ = index._byte_offsets.pop()
    with assert_raises(contains="grapheme boundary table is missing endpoint 2"):
        index.validate()
    index = GraphemeBoundaryIndex("")
    index._byte_offsets.append(1)
    with assert_raises(contains="grapheme boundary table has 2 entries; expected 1"):
        index.validate()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
