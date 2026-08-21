from moji import ByteOffset, GraphemeIndex


def main() raises:
    _ = ByteOffset(0) == GraphemeIndex(0)
