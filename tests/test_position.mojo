from moji import ByteOffset, CodePointIndex, DisplayColumn, GraphemeIndex
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_position_values_preserve_their_units() raises:
    assert_true(ByteOffset(7).value() == 7)
    assert_true(CodePointIndex(7).value() == 7)
    assert_true(GraphemeIndex(7).value() == 7)
    assert_true(DisplayColumn(7).value() == 7)


def test_positions_have_consistent_string_and_print_forms() raises:
    assert_equal(String(ByteOffset(7)), "7")
    assert_equal(String(CodePointIndex(7)), "7")
    assert_equal(String(GraphemeIndex(7)), "7")
    assert_equal(String(DisplayColumn(7)), "7")


def test_byte_offset_same_unit_arithmetic() raises:
    var offset = ByteOffset(7)
    assert_true(offset + 4 == ByteOffset(11))
    assert_true(offset + -7 == ByteOffset(0))
    assert_true(offset - 3 == ByteOffset(4))
    assert_true(offset - -2 == ByteOffset(9))
    assert_equal(ByteOffset(9) - ByteOffset(4), 5)
    assert_equal(ByteOffset(4) - ByteOffset(9), -5)


def test_byte_offset_arithmetic_rejects_negative_results() raises:
    with assert_raises(
        contains="byte offset arithmetic result must be nonnegative, got -2"
    ):
        _ = ByteOffset(3) + -5
    with assert_raises(
        contains="byte offset arithmetic result must be nonnegative, got -2"
    ):
        _ = ByteOffset(3) - 5


def test_display_column_same_unit_arithmetic() raises:
    var column = DisplayColumn(7)
    assert_true(column + 4 == DisplayColumn(11))
    assert_true(column + -7 == DisplayColumn(0))
    assert_true(column - 3 == DisplayColumn(4))
    assert_true(column - -2 == DisplayColumn(9))
    assert_equal(DisplayColumn(9) - DisplayColumn(4), 5)
    assert_equal(DisplayColumn(4) - DisplayColumn(9), -5)


def test_display_column_arithmetic_rejects_negative_results() raises:
    with assert_raises(
        contains="display column arithmetic result must be nonnegative, got -2"
    ):
        _ = DisplayColumn(3) + -5
    with assert_raises(
        contains="display column arithmetic result must be nonnegative, got -2"
    ):
        _ = DisplayColumn(3) - 5


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
    with assert_raises(contains="byte offset must be nonnegative, got -1"):
        byte_offset.validate()

    var codepoint_index = CodePointIndex(4)
    codepoint_index._value = -1
    assert_true(codepoint_index.value() == -1)
    with assert_raises(contains="code-point index must be nonnegative, got -1"):
        codepoint_index.validate()

    var grapheme_index = GraphemeIndex(4)
    grapheme_index._value = -1
    assert_true(grapheme_index.value() == -1)
    with assert_raises(contains="grapheme index must be nonnegative, got -1"):
        grapheme_index.validate()

    var display_column = DisplayColumn(4)
    display_column._value = -1
    assert_true(display_column.value() == -1)
    with assert_raises(contains="display column must be nonnegative, got -1"):
        display_column.validate()


def test_negative_positions_are_rejected() raises:
    with assert_raises(contains="byte offset must be nonnegative, got -1"):
        _ = ByteOffset(-1)
    with assert_raises(contains="code-point index must be nonnegative, got -1"):
        _ = CodePointIndex(-1)
    with assert_raises(contains="grapheme index must be nonnegative, got -1"):
        _ = GraphemeIndex(-1)
    with assert_raises(contains="display column must be nonnegative, got -1"):
        _ = DisplayColumn(-1)


def test_int_max_is_a_valid_position() raises:
    assert_true(ByteOffset(Int.MAX).value() == Int.MAX)
    assert_true(CodePointIndex(Int.MAX).value() == Int.MAX)
    assert_true(GraphemeIndex(Int.MAX).value() == Int.MAX)
    assert_true(DisplayColumn(Int.MAX).value() == Int.MAX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
