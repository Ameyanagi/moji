from moji import (
    ByteOffset,
    ByteRange,
    is_utf8_boundary,
    slice_text,
    validate_text_range,
)
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_byte_range_is_half_open() raises:
    var byte_range = ByteRange(2, 5)
    assert_equal(byte_range.start(), 2)
    assert_equal(byte_range.end(), 5)
    assert_equal(byte_range.byte_length(), 3)
    assert_false(byte_range.is_empty())
    assert_true(byte_range.contains(2))
    assert_true(byte_range.contains(4))
    assert_false(byte_range.contains(5))
    assert_false(byte_range.contains(1))


def test_byte_range_accepts_empty_ranges() raises:
    var byte_range = ByteRange(3, 3)
    assert_true(byte_range.is_empty())
    assert_equal(byte_range.byte_length(), 0)
    assert_false(byte_range.contains(3))


def test_byte_range_composes_byte_offsets() raises:
    var byte_range = ByteRange(ByteOffset(2), ByteOffset(5))
    assert_equal(byte_range.start(), 2)
    assert_equal(byte_range.end(), 5)


def test_byte_range_validate_rejects_mutated_storage() raises:
    var byte_range = ByteRange(2, 5)
    byte_range._start = -1
    assert_equal(byte_range.start(), -1)
    with assert_raises(contains="byte range start must be nonnegative, got -1"):
        byte_range.validate()

    byte_range._start = 2
    byte_range._end = 1
    assert_equal(byte_range.end(), 1)
    with assert_raises(contains="byte range end 1 must not precede start 2"):
        byte_range.validate()


def test_byte_range_rejects_negative_start() raises:
    with assert_raises(contains="byte range start must be nonnegative, got -1"):
        _ = ByteRange(-1, 0)


def test_byte_range_rejects_reversed_endpoints() raises:
    with assert_raises(contains="byte range end 1 must not precede start 2"):
        _ = ByteRange(2, 1)

    with assert_raises(contains="byte range end 1 must not precede start 2"):
        _ = ByteRange(ByteOffset(2), ByteOffset(1))


def test_byte_range_at_constructs_from_byte_length() raises:
    var byte_range = ByteRange.at(2, 3)
    assert_equal(byte_range.start(), 2)
    assert_equal(byte_range.end(), 5)


def test_byte_range_at_rejects_negative_start() raises:
    with assert_raises(contains="byte range start must be nonnegative, got -2"):
        _ = ByteRange.at(-2, 3)


def test_byte_range_at_rejects_negative_length() raises:
    with assert_raises(contains="byte range length must be nonnegative, got -3"):
        _ = ByteRange.at(2, -3)


def test_byte_range_empty_at_constructs_empty_byte_range() raises:
    var byte_range = ByteRange.empty_at(4)
    assert_equal(byte_range.start(), 4)
    assert_equal(byte_range.end(), 4)
    assert_true(byte_range.is_empty())


def test_byte_range_empty_at_rejects_negative_offset() raises:
    with assert_raises(contains="byte range offset must be nonnegative, got -4"):
        _ = ByteRange.empty_at(-4)


def test_byte_range_up_to_constructs_from_zero() raises:
    var byte_range = ByteRange.up_to(6)
    assert_equal(byte_range.start(), 0)
    assert_equal(byte_range.end(), 6)


def test_byte_range_up_to_rejects_negative_end() raises:
    with assert_raises(contains="byte range end must be nonnegative, got -5"):
        _ = ByteRange.up_to(-5)


def test_byte_range_contains_range_including_empty_boundaries() raises:
    var outer = ByteRange(2, 5)
    assert_true(outer.contains_range(ByteRange(2, 5)))
    assert_true(outer.contains_range(ByteRange(3, 4)))
    assert_true(outer.contains_range(ByteRange(2, 2)))
    assert_true(outer.contains_range(ByteRange(5, 5)))


def test_byte_range_contains_range_rejects_non_containment() raises:
    var outer = ByteRange(2, 5)
    assert_false(outer.contains_range(ByteRange(1, 4)))
    assert_false(outer.contains_range(ByteRange(3, 6)))


def test_byte_range_intersect_returns_overlap() raises:
    var intersection = ByteRange(1, 5).intersect(ByteRange(3, 7))
    assert_true(intersection)
    assert_true(intersection.value() == ByteRange(3, 5))


def test_byte_range_intersect_returns_empty_when_touching() raises:
    var intersection = ByteRange(1, 3).intersect(ByteRange(3, 7))
    assert_true(intersection)
    assert_true(intersection.value() == ByteRange.empty_at(3))


def test_byte_range_intersect_returns_none_when_disjoint() raises:
    var intersection = ByteRange(1, 3).intersect(ByteRange(4, 7))
    assert_false(intersection)


def test_byte_range_cover_spans_disjoint_ranges() raises:
    assert_true(ByteRange(1, 3).cover(ByteRange(5, 7)) == ByteRange(1, 7))


def test_byte_range_cover_preserves_outer_nested_range() raises:
    assert_true(ByteRange(1, 7).cover(ByteRange(3, 5)) == ByteRange(1, 7))


def test_byte_range_shifted_moves_by_positive_and_negative_bytes() raises:
    assert_true(ByteRange(3, 7).shifted(2) == ByteRange(5, 9))
    assert_true(ByteRange(3, 7).shifted(-3) == ByteRange(0, 4))


def test_byte_range_shifted_rejects_negative_start() raises:
    with assert_raises(contains="shifted byte range start must be nonnegative, got -1"):
        _ = ByteRange(2, 5).shifted(-3)


def test_utf8_boundaries_cover_ascii_and_multibyte_text() raises:
    var text = String("a界b")
    assert_true(is_utf8_boundary(text, 0))
    assert_true(is_utf8_boundary(text, 1))
    assert_false(is_utf8_boundary(text, 2))
    assert_false(is_utf8_boundary(text, 3))
    assert_true(is_utf8_boundary(text, 4))
    assert_true(is_utf8_boundary(text, 5))
    assert_false(is_utf8_boundary(text, -1))
    assert_false(is_utf8_boundary(text, 6))


def test_empty_text_has_one_boundary() raises:
    assert_true(is_utf8_boundary("", 0))
    assert_false(is_utf8_boundary("", 1))


def test_empty_text_accepts_its_empty_range() raises:
    var empty_range = ByteRange(0, 0)
    validate_text_range("", empty_range)
    assert_equal(slice_text("", empty_range), "")


def test_safe_slice_handles_ascii_cjk_and_emoji() raises:
    var text = String("A界🙂Z")
    assert_equal(slice_text(text, ByteRange(0, 1)), "A")
    assert_equal(slice_text(text, ByteRange(1, 4)), "界")
    assert_equal(slice_text(text, ByteRange(4, 8)), "🙂")
    assert_equal(slice_text(text, ByteRange(1, 8)), "界🙂")
    assert_equal(slice_text(text, ByteRange(9, 9)), "")


def test_safe_slice_rejects_out_of_bounds_range() raises:
    with assert_raises(contains="byte range end 4 is outside text byte length 3"):
        _ = slice_text("abc", ByteRange(0, 4))


def test_safe_slice_rejects_interior_start() raises:
    with assert_raises(
        contains="byte offset 1 splits U+754C; nearest boundaries are 0 and 3"
    ):
        _ = slice_text("界", ByteRange(1, 3))


def test_safe_slice_rejects_interior_end() raises:
    with assert_raises(
        contains="byte offset 2 splits U+754C; nearest boundaries are 0 and 3"
    ):
        _ = slice_text("界", ByteRange(0, 2))


def test_safe_slice_rejects_empty_range_inside_codepoint() raises:
    with assert_raises(
        contains="byte offset 1 splits U+754C; nearest boundaries are 0 and 3"
    ):
        _ = slice_text("界", ByteRange(1, 1))


def test_validation_allows_codepoint_boundary_inside_grapheme() raises:
    # `e` plus COMBINING ACUTE ACCENT is one grapheme but two code points.
    var text = String("é")
    validate_text_range(text, ByteRange(0, 1))
    assert_equal(slice_text(text, ByteRange(0, 1)), "e")
    assert_equal(slice_text(text, ByteRange(1, 3)), "́")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
