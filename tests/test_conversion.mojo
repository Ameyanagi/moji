from moji import (
    ByteOffset,
    CodePointIndex,
    byte_offset_of,
    code_point_index,
    count_code_points,
    floor_utf8_boundary,
)
from std.testing import TestSuite, assert_equal, assert_raises


def test_count_code_points_handles_ascii_cjk_and_emoji() raises:
    assert_equal(count_code_points("a北京b🇯🇵c"), 7)
    assert_equal(count_code_points(""), 0)


def test_code_point_index_maps_byte_boundaries() raises:
    var text = String("a北京b🇯🇵c")
    assert_equal(code_point_index(text, ByteOffset(0)).value(), 0)
    assert_equal(code_point_index(text, ByteOffset(1)).value(), 1)
    assert_equal(code_point_index(text, ByteOffset(4)).value(), 2)
    assert_equal(code_point_index(text, ByteOffset(8)).value(), 4)
    assert_equal(code_point_index(text, ByteOffset(12)).value(), 5)
    assert_equal(code_point_index(text, ByteOffset(16)).value(), 6)
    assert_equal(code_point_index(text, ByteOffset(17)).value(), 7)


def test_byte_offset_of_maps_code_point_indices() raises:
    var text = String("a北京b🇯🇵c")
    assert_equal(byte_offset_of(text, CodePointIndex(0)).value(), 0)
    assert_equal(byte_offset_of(text, CodePointIndex(1)).value(), 1)
    assert_equal(byte_offset_of(text, CodePointIndex(2)).value(), 4)
    assert_equal(byte_offset_of(text, CodePointIndex(4)).value(), 8)
    assert_equal(byte_offset_of(text, CodePointIndex(5)).value(), 12)
    assert_equal(byte_offset_of(text, CodePointIndex(6)).value(), 16)
    assert_equal(byte_offset_of(text, CodePointIndex(7)).value(), 17)


def test_cjk_conversions_and_final_endpoints_round_trip() raises:
    var text = String("北京")
    assert_equal(code_point_index(text, ByteOffset(3)).value(), 1)
    assert_equal(byte_offset_of(text, CodePointIndex(2)).value(), 6)
    assert_equal(code_point_index(text, ByteOffset(6)).value(), 2)
    assert_equal(byte_offset_of(text, CodePointIndex(0)).value(), 0)


def test_conversion_accepts_empty_text_final_endpoint() raises:
    assert_equal(code_point_index("", ByteOffset(0)).value(), 0)
    assert_equal(byte_offset_of("", CodePointIndex(0)).value(), 0)


def test_code_point_index_rejects_offset_past_end() raises:
    with assert_raises(contains="byte offset 7 is outside text byte length 6"):
        _ = code_point_index("北京", ByteOffset(7))


def test_byte_offset_of_rejects_index_past_final_endpoint() raises:
    with assert_raises(contains="code-point index 3 is past final endpoint 2"):
        _ = byte_offset_of("北京", CodePointIndex(3))


def test_code_point_index_rejects_mid_code_point_with_teaching_message() raises:
    with assert_raises(
        contains="byte offset 4 splits U+4EAC; nearest boundaries are 3 and 6"
    ):
        _ = code_point_index("北京", ByteOffset(4))


def test_floor_utf8_boundary_is_total() raises:
    var text = String("北京")
    assert_equal(floor_utf8_boundary(text, -4).value(), 0)
    assert_equal(floor_utf8_boundary(text, 4).value(), 3)
    assert_equal(floor_utf8_boundary(text, 9).value(), 6)
    assert_equal(floor_utf8_boundary(text, 3).value(), 3)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
