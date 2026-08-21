from moji import ByteRange, slice_text
from std.testing import TestSuite, assert_equal


def test_primary_public_api() raises:
    assert_equal(slice_text("a界b", ByteRange(1, 4)), "界")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
