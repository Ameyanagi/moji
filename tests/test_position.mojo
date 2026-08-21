from moji import ByteOffset, CodePointIndex, DisplayColumn, GraphemeIndex
from std.testing import TestSuite, assert_false, assert_raises, assert_true


def test_position_values_preserve_their_units() raises:
    assert_true(ByteOffset(7).value() == 7)
    assert_true(CodePointIndex(7).value() == 7)
    assert_true(GraphemeIndex(7).value() == 7)
    assert_true(DisplayColumn(7).value() == 7)


def test_byte_offset_total_order_handles_extremes() raises:
    var zero = ByteOffset(0)
    var maximum = ByteOffset(Int.MAX)
    assert_true(zero == ByteOffset(0))
    assert_true(zero <= ByteOffset(0))
    assert_true(zero >= ByteOffset(0))
    assert_false(zero < ByteOffset(0))
    assert_false(zero > ByteOffset(0))
    assert_true(zero < maximum)
    assert_true(maximum > zero)
    assert_true(maximum <= ByteOffset(Int.MAX))
    assert_true(maximum >= ByteOffset(Int.MAX))


def test_codepoint_index_total_order_handles_extremes() raises:
    var zero = CodePointIndex(0)
    var maximum = CodePointIndex(Int.MAX)
    assert_true(zero == CodePointIndex(0))
    assert_true(zero <= CodePointIndex(0))
    assert_true(zero >= CodePointIndex(0))
    assert_false(zero < CodePointIndex(0))
    assert_false(zero > CodePointIndex(0))
    assert_true(zero < maximum)
    assert_true(maximum > zero)
    assert_true(maximum <= CodePointIndex(Int.MAX))
    assert_true(maximum >= CodePointIndex(Int.MAX))


def test_grapheme_index_total_order_handles_extremes() raises:
    var zero = GraphemeIndex(0)
    var maximum = GraphemeIndex(Int.MAX)
    assert_true(zero == GraphemeIndex(0))
    assert_true(zero <= GraphemeIndex(0))
    assert_true(zero >= GraphemeIndex(0))
    assert_false(zero < GraphemeIndex(0))
    assert_false(zero > GraphemeIndex(0))
    assert_true(zero < maximum)
    assert_true(maximum > zero)
    assert_true(maximum <= GraphemeIndex(Int.MAX))
    assert_true(maximum >= GraphemeIndex(Int.MAX))


def test_display_column_total_order_handles_extremes() raises:
    var zero = DisplayColumn(0)
    var maximum = DisplayColumn(Int.MAX)
    assert_true(zero == DisplayColumn(0))
    assert_true(zero <= DisplayColumn(0))
    assert_true(zero >= DisplayColumn(0))
    assert_false(zero < DisplayColumn(0))
    assert_false(zero > DisplayColumn(0))
    assert_true(zero < maximum)
    assert_true(maximum > zero)
    assert_true(maximum <= DisplayColumn(Int.MAX))
    assert_true(maximum >= DisplayColumn(Int.MAX))


def test_validate_rejects_mutated_position_storage() raises:
    var byte_offset = ByteOffset(4)
    byte_offset._value = -1
    assert_true(byte_offset.value() == -1)
    with assert_raises(contains="byte offset must be nonnegative"):
        byte_offset.validate()

    var codepoint_index = CodePointIndex(4)
    codepoint_index._value = -1
    assert_true(codepoint_index.value() == -1)
    with assert_raises(contains="code-point index must be nonnegative"):
        codepoint_index.validate()

    var grapheme_index = GraphemeIndex(4)
    grapheme_index._value = -1
    assert_true(grapheme_index.value() == -1)
    with assert_raises(contains="grapheme index must be nonnegative"):
        grapheme_index.validate()

    var display_column = DisplayColumn(4)
    display_column._value = -1
    assert_true(display_column.value() == -1)
    with assert_raises(contains="display column must be nonnegative"):
        display_column.validate()


def test_negative_positions_are_rejected() raises:
    with assert_raises(contains="byte offset must be nonnegative"):
        _ = ByteOffset(-1)
    with assert_raises(contains="code-point index must be nonnegative"):
        _ = CodePointIndex(-1)
    with assert_raises(contains="grapheme index must be nonnegative"):
        _ = GraphemeIndex(-1)
    with assert_raises(contains="display column must be nonnegative"):
        _ = DisplayColumn(-1)


def test_int_max_is_a_valid_position() raises:
    assert_true(ByteOffset(Int.MAX).value() == Int.MAX)
    assert_true(CodePointIndex(Int.MAX).value() == Int.MAX)
    assert_true(GraphemeIndex(Int.MAX).value() == Int.MAX)
    assert_true(DisplayColumn(Int.MAX).value() == Int.MAX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
