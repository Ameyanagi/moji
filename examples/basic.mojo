from moji import (
    ByteOffset,
    ByteRange,
    ColumnSnap,
    DisplayColumn,
    byte_offset_at_column,
    slice_text,
    text_width,
)


def truncate_filename(text: StringSlice, columns: Int) raises -> String:
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
    var label = String("北京 👨‍👩‍👧‍👦")
    print("width:", text_width(label))

    var filename = String("2026-北京旅行-家族👨‍👩‍👧‍👦-notes.txt")
    print(truncate_filename(filename, 20))

    print(slice_text("a北京b", ByteRange(1, 7)))
