from moji import ByteRange, byte_ranges_of_code_points, slice_text, text_width
from std.collections import List


def render_highlights(
    text: StringSlice,
    viewport: ByteRange,
    highlights: List[ByteRange],
) raises -> String:
    """Render sorted byte ranges clipped to a viewport with reverse video."""
    var rendered = String()
    var current = viewport.start()
    for highlight in highlights:
        var intersection = viewport.intersect(highlight)
        if intersection:
            var clipped = intersection.value()
            if not clipped.is_empty():
                rendered += slice_text(text, ByteRange(current, clipped.start()))
                rendered += "\x1b[7m"
                rendered += slice_text(text, clipped)
                rendered += "\x1b[0m"
                current = clipped.end()
    rendered += slice_text(text, ByteRange(current, viewport.end()))
    return rendered^


def pad_visible(rendered: StringSlice, visible: StringSlice, columns: Int) -> String:
    var padded = String(rendered)
    for _ in range(max(columns - text_width(visible), 0)):
        padded += " "
    return padded^


def main() raises:
    var text = String("a北京b🇯🇵c")
    var positions: List[Int] = [1, 2, 4, 5]
    # Hibana-shaped scalar positions become [ByteRange(1, 7), ByteRange(8, 16)].
    var highlights = byte_ranges_of_code_points(text, positions)

    var viewport = ByteRange(1, text.byte_length())
    var visible = slice_text(text, viewport)
    var rendered = render_highlights(text, viewport, highlights)
    print(String("|", pad_visible(rendered, visible, 16), "| match"))
