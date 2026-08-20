from moji import ByteRange, slice_text
from std.testing import assert_equal


def main() raises:
    assert_equal(slice_text("a界b", ByteRange(1, 4)), "界")
