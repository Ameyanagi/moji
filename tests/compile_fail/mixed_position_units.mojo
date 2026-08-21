from moji import ByteOffset, CodePointIndex


def requires_byte_offset(value: ByteOffset):
    _ = value


def main() raises:
    requires_byte_offset(CodePointIndex(0))
