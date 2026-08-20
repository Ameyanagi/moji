from moji import ByteRange, slice_text


def main() raises:
    var text = String("北京 notes")
    var city = slice_text(text, ByteRange(0, 6))
    print(city)
