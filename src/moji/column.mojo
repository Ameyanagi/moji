"""Conversions between grapheme-safe UTF-8 offsets and display columns."""

from .grapheme import _grapheme_boundary_error_message, grapheme_spans
from .position import ByteOffset, DisplayColumn
from .width import AmbiguousWidth, grapheme_width


struct ColumnSnap(Copyable, Equatable, ImplicitlyCopyable):
    """Select how display-column conversion handles non-boundary columns."""

    var _value: Int

    comptime REJECT = ColumnSnap(_value=0)
    comptime FLOOR = ColumnSnap(_value=1)

    def __init__(out self, *, _value: Int):
        self._value = _value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value


def display_column(
    text: StringSlice,
    offset: ByteOffset,
    ambiguous: AmbiguousWidth = AmbiguousWidth.NARROW,
) raises -> DisplayColumn:
    """Convert a grapheme-boundary UTF-8 byte offset to a display column.

    Width is measured in terminal columns under `ambiguous`. Raises when the
    byte offset is outside `text` or inside an extended grapheme cluster. The
    final UTF-8 byte endpoint maps to the text's display width.
    """
    var target = offset.value()
    var byte_length = text.byte_length()
    if target > byte_length:
        raise Error(
            String(
                "byte offset ",
                target,
                " is outside text byte length ",
                byte_length,
            )
        )

    var column = 0
    for span in grapheme_spans(text):
        var byte_range = span.byte_range()
        if target == byte_range.start():
            return DisplayColumn._from_validated(column)
        if target < byte_range.end():
            raise Error(
                _grapheme_boundary_error_message(
                    target, byte_range.start(), byte_range.end()
                )
            )
        column += grapheme_width(span.text(), ambiguous)
    return DisplayColumn._from_validated(column)


def byte_offset_at_column(
    text: StringSlice,
    column: DisplayColumn,
    snap: ColumnSnap = ColumnSnap.FLOOR,
    ambiguous: AmbiguousWidth = AmbiguousWidth.NARROW,
) raises -> ByteOffset:
    """Convert a display column to a grapheme-boundary UTF-8 byte offset.

    Columns and widths use `ambiguous`. An exact cluster boundary returns its
    byte offset. A column inside a multi-column cluster snaps left under
    `ColumnSnap.FLOOR` and raises under `ColumnSnap.REJECT`. Columns beyond the
    text width clamp to the final byte endpoint under `FLOOR` and raise under
    `REJECT`.
    """
    var target = column.value()
    var current_column = 0
    for span in grapheme_spans(text):
        var byte_range = span.byte_range()
        if target == current_column:
            return ByteOffset._from_validated(byte_range.start())

        var width = grapheme_width(span.text(), ambiguous)
        var next_column = current_column + width
        if target < next_column:
            if snap == ColumnSnap.REJECT:
                raise Error(
                    String(
                        "column ",
                        target,
                        " is inside a ",
                        width,
                        "-column grapheme spanning columns ",
                        current_column,
                        "..",
                        next_column,
                    )
                )
            return ByteOffset._from_validated(byte_range.start())
        current_column = next_column

    if target == current_column or snap == ColumnSnap.FLOOR:
        return ByteOffset._from_validated(text.byte_length())
    raise Error(
        String(
            "column ",
            target,
            " is past text display width ",
            current_column,
        )
    )
