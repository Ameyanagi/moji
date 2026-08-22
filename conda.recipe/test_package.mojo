from moji import (
    ByteOffset,
    ByteRange,
    CodePointIndex,
    DisplayColumn,
    GraphemeIndex,
    MappedText,
    TextIndex,
    byte_offset_at_column,
    text_width,
)
from moji import slice_text
from std.collections import List
from std.testing import assert_equal, assert_true


def main() raises:
    assert_equal(slice_text("a界b", ByteRange(1, 4)), "界")
    assert_true(ByteOffset(1) < ByteOffset(4))
    assert_equal(CodePointIndex(2).value(), 2)
    assert_equal(GraphemeIndex(2).value(), 2)
    assert_equal(DisplayColumn(2).value(), 2)
    assert_equal(text_width("北京 👨‍👩‍👧‍👦"), 7)
    assert_true(byte_offset_at_column("a界b", DisplayColumn(3)) == ByteOffset(4))
    assert_equal(TextIndex("a界b").byte_offset(CodePointIndex(2)).value(), 4)
    var origins: List[ByteRange] = [ByteRange(0, 3), ByteRange(0, 3)]
    assert_equal(MappedText("北", "be", origins).source_text(), "北")
