from moji import ByteOffset, ByteRange, CodePointIndex, MappedText, TextIndex
from std.collections import List


def main() raises:
    # Build once when an editor, matcher, or renderer will query the same text
    # repeatedly. ASCII positions use an allocation-free identity fast path.
    var index = TextIndex("a北京b🇯🇵c")
    print("scalar 4 begins at byte", index.byte_offset(CodePointIndex(4)))
    print("byte 8 is scalar", index.code_point_index(ByteOffset(8)))

    # A transform supplies one exact source range for each output scalar.
    var origins: List[ByteRange] = [
        ByteRange(0, 3),
        ByteRange(0, 3),
        ByteRange(0, 3),
        ByteRange(3, 6),
        ByteRange(3, 6),
        ByteRange(3, 6),
        ByteRange(3, 6),
    ]
    var reading = MappedText("北京", "beijing", origins)
    var source_ranges = reading.source_ranges(ByteRange(0, 3))
    print("bei maps to source bytes", source_ranges[0])
