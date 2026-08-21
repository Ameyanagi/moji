from moji import (
    ByteOffset,
    ByteRange,
    ColumnSnap,
    DisplayColumn,
    GraphemeIndex,
    byte_offset_at_column,
    count_graphemes,
    slice_graphemes,
    slice_text,
    text_width,
)


def truncate_with_ellipsis(text: StringSlice, columns: Int) raises -> String:
    """Copy text truncated to at most `columns`, including an ellipsis."""
    if columns <= 0:
        return String()
    if text_width(text) <= columns:
        return String(text)

    var ellipsis = String("…")
    var content_columns = max(columns - text_width(ellipsis), 0)
    var end = byte_offset_at_column(
        text,
        DisplayColumn(content_columns),
        ColumnSnap.FLOOR,
    )
    return String(
        slice_text(text, ByteRange(ByteOffset(0), end)),
        ellipsis,
    )


def main() raises:
    var input = String("hi👨‍👩‍👧‍👦")
    var cluster_count = count_graphemes(input)
    var after_backspace = slice_graphemes(
        input,
        GraphemeIndex(0),
        GraphemeIndex(cluster_count - 1),
    )
    print(after_backspace)

    var title = String("東京から北京への長い旅行計画")
    var truncated = truncate_with_ellipsis(title, 12)
    print(truncated, "width:", text_width(truncated))
