from moji import ByteOffset, CodePointIndex, DisplayColumn, GraphemeIndex
from std.testing import TestSuite, assert_false, assert_raises, assert_true


def test_position_values_preserve_their_units() raises:
    assert_true(ByteOffset(7).value() == 7)
    assert_true(CodePointIndex(7).value() == 7)
    assert_true(GraphemeIndex(7).value() == 7)
    assert_true(DisplayColumn(7).value() == 7)


def test_byte_offset_total_order_survives_mutated_extremes() raises:
    var normalized_zero = ByteOffset(4)
    normalized_zero._value_hint = Int.MIN
    var zero = ByteOffset(0)
    var maximum = ByteOffset(4)
    maximum._value_hint = Int.MAX
    assert_true(normalized_zero.value() == 0)
    assert_true(normalized_zero == zero)
    assert_true(normalized_zero <= zero)
    assert_true(normalized_zero >= zero)
    assert_false(normalized_zero < zero)
    assert_false(normalized_zero > zero)
    assert_true(normalized_zero < maximum)
    assert_true(maximum > normalized_zero)
    assert_true(maximum <= ByteOffset(Int.MAX))
    assert_true(maximum >= ByteOffset(Int.MAX))


def test_codepoint_index_total_order_survives_mutated_extremes() raises:
    var normalized_zero = CodePointIndex(4)
    normalized_zero._value_hint = Int.MIN
    var zero = CodePointIndex(0)
    var maximum = CodePointIndex(4)
    maximum._value_hint = Int.MAX
    assert_true(normalized_zero.value() == 0)
    assert_true(normalized_zero == zero)
    assert_true(normalized_zero <= zero)
    assert_true(normalized_zero >= zero)
    assert_false(normalized_zero < zero)
    assert_false(normalized_zero > zero)
    assert_true(normalized_zero < maximum)
    assert_true(maximum > normalized_zero)
    assert_true(maximum <= CodePointIndex(Int.MAX))
    assert_true(maximum >= CodePointIndex(Int.MAX))


def test_grapheme_index_total_order_survives_mutated_extremes() raises:
    var normalized_zero = GraphemeIndex(4)
    normalized_zero._value_hint = Int.MIN
    var zero = GraphemeIndex(0)
    var maximum = GraphemeIndex(4)
    maximum._value_hint = Int.MAX
    assert_true(normalized_zero.value() == 0)
    assert_true(normalized_zero == zero)
    assert_true(normalized_zero <= zero)
    assert_true(normalized_zero >= zero)
    assert_false(normalized_zero < zero)
    assert_false(normalized_zero > zero)
    assert_true(normalized_zero < maximum)
    assert_true(maximum > normalized_zero)
    assert_true(maximum <= GraphemeIndex(Int.MAX))
    assert_true(maximum >= GraphemeIndex(Int.MAX))


def test_display_column_total_order_survives_mutated_extremes() raises:
    var normalized_zero = DisplayColumn(4)
    normalized_zero._value_hint = Int.MIN
    var zero = DisplayColumn(0)
    var maximum = DisplayColumn(4)
    maximum._value_hint = Int.MAX
    assert_true(normalized_zero.value() == 0)
    assert_true(normalized_zero == zero)
    assert_true(normalized_zero <= zero)
    assert_true(normalized_zero >= zero)
    assert_false(normalized_zero < zero)
    assert_false(normalized_zero > zero)
    assert_true(normalized_zero < maximum)
    assert_true(maximum > normalized_zero)
    assert_true(maximum <= DisplayColumn(Int.MAX))
    assert_true(maximum >= DisplayColumn(Int.MAX))


def test_negative_positions_are_rejected() raises:
    with assert_raises():
        _ = ByteOffset(-1)
    with assert_raises():
        _ = CodePointIndex(-1)
    with assert_raises():
        _ = GraphemeIndex(-1)
    with assert_raises():
        _ = DisplayColumn(-1)


def test_int_max_is_a_valid_position() raises:
    assert_true(ByteOffset(Int.MAX).value() == Int.MAX)
    assert_true(CodePointIndex(Int.MAX).value() == Int.MAX)
    assert_true(GraphemeIndex(Int.MAX).value() == Int.MAX)
    assert_true(DisplayColumn(Int.MAX).value() == Int.MAX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
