from moji import ByteRange, is_utf8_boundary, slice_text, validate_text_range
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
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


def test_storage_mutation_cannot_violate_semantic_invariants() raises:
    # Mojo 1.0 has no enforced field privacy. The underscore fields are not API,
    # but every possible mutation must still produce nonnegative ordered bounds.
    var byte_range = ByteRange(2, 5)
    byte_range._start_hint = -100
    byte_range._length_hint = Int.MAX
    assert_equal(byte_range.start(), 0)
    assert_equal(byte_range.end(), Int.MAX)
    assert_equal(byte_range.byte_length(), Int.MAX)

    byte_range._start_hint = Int.MAX
    byte_range._length_hint = Int.MAX
    assert_equal(byte_range.start(), Int.MAX)
    assert_equal(byte_range.end(), Int.MAX)
    assert_true(byte_range.is_empty())


def test_byte_range_rejects_negative_start() raises:
    try:
        _ = ByteRange(-1, 0)
    except:
        return
    raise Error("expected a negative byte range start to be rejected")


def test_byte_range_rejects_reversed_endpoints() raises:
    try:
        _ = ByteRange(2, 1)
    except:
        return
    raise Error("expected reversed byte range endpoints to be rejected")


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


def test_safe_slice_handles_ascii_cjk_and_emoji() raises:
    var text = String("A界🙂Z")
    assert_equal(slice_text(text, ByteRange(0, 1)), "A")
    assert_equal(slice_text(text, ByteRange(1, 4)), "界")
    assert_equal(slice_text(text, ByteRange(4, 8)), "🙂")
    assert_equal(slice_text(text, ByteRange(1, 8)), "界🙂")
    assert_equal(slice_text(text, ByteRange(9, 9)), "")


def test_safe_slice_rejects_out_of_bounds_range() raises:
    try:
        _ = slice_text("abc", ByteRange(0, 4))
    except:
        return
    raise Error("expected an out-of-bounds byte range to be rejected")


def test_safe_slice_rejects_interior_start() raises:
    try:
        _ = slice_text("界", ByteRange(1, 3))
    except:
        return
    raise Error("expected a range starting inside UTF-8 to be rejected")


def test_safe_slice_rejects_interior_end() raises:
    try:
        _ = slice_text("界", ByteRange(0, 2))
    except:
        return
    raise Error("expected a range ending inside UTF-8 to be rejected")


def test_safe_slice_rejects_empty_range_inside_codepoint() raises:
    try:
        _ = slice_text("界", ByteRange(1, 1))
    except:
        return
    raise Error("expected an empty range inside UTF-8 to be rejected")


def test_validation_allows_codepoint_boundary_inside_grapheme() raises:
    # `e` plus COMBINING ACUTE ACCENT is one grapheme but two code points.
    var text = String("é")
    validate_text_range(text, ByteRange(0, 1))
    assert_equal(slice_text(text, ByteRange(0, 1)), "e")
    assert_equal(slice_text(text, ByteRange(1, 3)), "́")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
