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
    with assert_raises(contains="byte range start must be nonnegative"):
        byte_range.validate()

    byte_range._start = 2
    byte_range._end = 1
    assert_equal(byte_range.end(), 1)
    with assert_raises(contains="byte range end must not precede start"):
        byte_range.validate()


def test_byte_range_rejects_negative_start() raises:
    with assert_raises(contains="byte range start must be nonnegative"):
        _ = ByteRange(-1, 0)


def test_byte_range_rejects_reversed_endpoints() raises:
    with assert_raises(contains="byte range end must not precede start"):
        _ = ByteRange(2, 1)

    with assert_raises(contains="byte range end must not precede start"):
        _ = ByteRange(ByteOffset(2), ByteOffset(1))


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
    with assert_raises(contains="byte range is outside the text"):
        _ = slice_text("abc", ByteRange(0, 4))


def test_safe_slice_rejects_interior_start() raises:
    with assert_raises(contains="byte range start splits a UTF-8 code point"):
        _ = slice_text("界", ByteRange(1, 3))


def test_safe_slice_rejects_interior_end() raises:
    with assert_raises(contains="byte range end splits a UTF-8 code point"):
        _ = slice_text("界", ByteRange(0, 2))


def test_safe_slice_rejects_empty_range_inside_codepoint() raises:
    with assert_raises(contains="byte range start splits a UTF-8 code point"):
        _ = slice_text("界", ByteRange(1, 1))


def test_validation_allows_codepoint_boundary_inside_grapheme() raises:
    # `e` plus COMBINING ACUTE ACCENT is one grapheme but two code points.
    var text = String("é")
    validate_text_range(text, ByteRange(0, 1))
    assert_equal(slice_text(text, ByteRange(0, 1)), "e")
    assert_equal(slice_text(text, ByteRange(1, 3)), "́")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
