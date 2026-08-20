from moji import ByteOffset, CodePointIndex, DisplayColumn, GraphemeIndex
from std.testing import TestSuite, assert_raises, assert_true


def test_position_values_preserve_their_units() raises:
    assert_true(ByteOffset(7).value() == 7)
    assert_true(CodePointIndex(7).value() == 7)
    assert_true(GraphemeIndex(7).value() == 7)
    assert_true(DisplayColumn(7).value() == 7)


def test_position_equality_and_order_are_same_unit() raises:
    assert_true(ByteOffset(2) == ByteOffset(2))
    assert_true(ByteOffset(2) < ByteOffset(3))
    assert_true(ByteOffset(2) <= ByteOffset(2))
    assert_true(ByteOffset(3) > ByteOffset(2))
    assert_true(ByteOffset(3) >= ByteOffset(3))
    assert_true(CodePointIndex(2) < CodePointIndex(3))
    assert_true(GraphemeIndex(2) < GraphemeIndex(3))
    assert_true(DisplayColumn(2) < DisplayColumn(3))


def test_negative_positions_are_rejected() raises:
    with assert_raises():
        _ = ByteOffset(-1)
    with assert_raises():
        _ = CodePointIndex(-1)
    with assert_raises():
        _ = GraphemeIndex(-1)
    with assert_raises():
        _ = DisplayColumn(-1)


def test_external_storage_mutation_remains_nonnegative() raises:
    var byte_offset = ByteOffset(4)
    byte_offset._value_hint = Int.MIN
    assert_true(byte_offset.value() == 0)
    assert_true(byte_offset == ByteOffset(0))

    var codepoint_index = CodePointIndex(4)
    codepoint_index._value_hint = -9
    assert_true(codepoint_index.value() == 0)

    var grapheme_index = GraphemeIndex(4)
    grapheme_index._value_hint = -9
    assert_true(grapheme_index.value() == 0)

    var display_column = DisplayColumn(4)
    display_column._value_hint = -9
    assert_true(display_column.value() == 0)


def test_int_max_is_a_valid_position() raises:
    assert_true(ByteOffset(Int.MAX).value() == Int.MAX)
    assert_true(CodePointIndex(Int.MAX).value() == Int.MAX)
    assert_true(GraphemeIndex(Int.MAX).value() == Int.MAX)
    assert_true(DisplayColumn(Int.MAX).value() == Int.MAX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
