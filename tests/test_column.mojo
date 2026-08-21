from moji import (
    AmbiguousWidth,
    ByteOffset,
    ColumnSnap,
    DisplayColumn,
    byte_offset_at_column,
    display_column,
    text_width,
)
from std.collections import List
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_column_snap_values_are_nominal_and_equatable() raises:
    assert_true(ColumnSnap.FLOOR == ColumnSnap.FLOOR)
    assert_true(ColumnSnap.REJECT == ColumnSnap.REJECT)
    assert_true(not (ColumnSnap.FLOOR == ColumnSnap.REJECT))


def test_ascii_column_conversions() raises:
    var text = String("abc")
    for value in range(4):
        assert_equal(
            display_column(text, ByteOffset(value)).value(),
            value,
        )
        assert_equal(
            byte_offset_at_column(text, DisplayColumn(value)).value(),
            value,
        )


def test_cjk_column_floor_reject_and_boundary_mapping() raises:
    var text = String("北京")
    assert_equal(
        byte_offset_at_column(text, DisplayColumn(1), ColumnSnap.FLOOR).value(),
        0,
    )
    with assert_raises(
        contains="column 1 is inside a 2-column grapheme spanning columns 0..2"
    ):
        _ = byte_offset_at_column(text, DisplayColumn(1), ColumnSnap.REJECT)
    assert_equal(byte_offset_at_column(text, DisplayColumn(2)).value(), 3)
    assert_equal(display_column(text, ByteOffset(3)).value(), 2)


def test_display_column_rejects_offset_inside_grapheme() raises:
    with assert_raises(
        contains=(
            "byte offset 1 is inside a grapheme cluster; nearest boundaries are 0 and 3"
        )
    ):
        _ = display_column("北", ByteOffset(1))


def test_emoji_zwj_cluster_is_one_two_column_unit() raises:
    var family = String("👨‍👩‍👧‍👦")
    assert_equal(text_width(family), 2)
    assert_equal(byte_offset_at_column(family, DisplayColumn(1)).value(), 0)
    assert_equal(byte_offset_at_column(family, DisplayColumn(2)).value(), 25)
    assert_equal(display_column(family, ByteOffset(25)).value(), 2)
    with assert_raises(
        contains=(
            "byte offset 4 is inside a grapheme cluster; nearest boundaries "
            "are 0 and 25"
        )
    ):
        _ = display_column(family, ByteOffset(4))


def test_final_and_past_end_columns_follow_snap_policy() raises:
    var text = String("北京")
    assert_equal(text_width(text), 4)
    assert_equal(byte_offset_at_column(text, DisplayColumn(4)).value(), 6)
    assert_equal(
        byte_offset_at_column(text, DisplayColumn(7), ColumnSnap.FLOOR).value(),
        6,
    )
    with assert_raises(contains="column 7 is past text display width 4"):
        _ = byte_offset_at_column(text, DisplayColumn(7), ColumnSnap.REJECT)


def test_ambiguous_width_changes_column_mapping() raises:
    var text = String("§x")
    assert_equal(display_column(text, ByteOffset(2)).value(), 1)
    assert_equal(
        display_column(text, ByteOffset(2), AmbiguousWidth.WIDE).value(),
        2,
    )
    assert_equal(byte_offset_at_column(text, DisplayColumn(1)).value(), 2)
    assert_equal(
        byte_offset_at_column(
            text,
            DisplayColumn(1),
            ColumnSnap.FLOOR,
            AmbiguousWidth.WIDE,
        ).value(),
        0,
    )
    assert_equal(
        byte_offset_at_column(
            text,
            DisplayColumn(2),
            ColumnSnap.FLOOR,
            AmbiguousWidth.WIDE,
        ).value(),
        2,
    )


def test_boundary_columns_round_trip() raises:
    var text = String("a北京👨‍👩‍👧‍👦")
    var boundaries: List[Int] = [0, 1, 3, 5, 7]
    for value in boundaries:
        var offset = byte_offset_at_column(text, DisplayColumn(value))
        assert_equal(display_column(text, offset).value(), value)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
