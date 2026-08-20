from moji import ByteOffset, ByteRange, slice_text


def main() raises:
    var text = String("北京 notes")
    var city_start = ByteOffset(0)
    var city_end = ByteOffset(6)
    var city = slice_text(text, ByteRange(city_start, city_end))
    print(city)
