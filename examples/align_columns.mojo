from moji import text_width


def pad_right(text: StringSlice, columns: Int) -> String:
    """Pad text with spaces to at least the requested terminal-column width."""
    var padded = String(text)
    for _ in range(max(columns - text_width(text), 0)):
        padded += " "
    return padded^


def print_row(left: StringSlice, right: StringSlice):
    print(String(pad_right(left, 14), right))


def main():
    print_row("場所", "天気")
    print_row("東京", "晴れ ☀️")
    print_row("北京", "雨 ☂️")
    print_row("家族 👨‍👩‍👧‍👦", "到着")
