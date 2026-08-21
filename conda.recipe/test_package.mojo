from moji import ByteOffset, ByteRange, CodePointIndex, DisplayColumn, GraphemeIndex
from moji import slice_text
from std.testing import assert_equal, assert_true


def main() raises:
    assert_equal(slice_text("a界b", ByteRange(1, 4)), "界")
    assert_true(ByteOffset(1) < ByteOffset(4))
    assert_equal(CodePointIndex(2).value(), 2)
    assert_equal(GraphemeIndex(2).value(), 2)
    assert_equal(DisplayColumn(2).value(), 2)
