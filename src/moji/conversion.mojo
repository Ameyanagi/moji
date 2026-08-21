"""Strict and total conversions between UTF-8 bytes and code-point indices."""

from .byte_range import (
    ByteRange,
    _floor_utf8_boundary_index,
    _utf8_boundary_error_message,
)
from .position import ByteOffset, CodePointIndex
from std.collections import List, Span


def code_point_index(text: StringSlice, offset: ByteOffset) raises -> CodePointIndex:
    """Convert a UTF-8 byte offset to a Unicode code-point index.

    The final byte endpoint is valid. Raises when `offset` is past that endpoint
    or splits a multi-byte code point; otherwise the conversion is well-defined.
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
    if not text.is_codepoint_boundary(target):
        raise Error(_utf8_boundary_error_message(text, target))

    var index = 0
    var current_offset = 0
    for code_point in text.codepoints():
        if current_offset == target:
            return CodePointIndex._from_validated(index)
        current_offset += code_point.utf8_byte_length()
        index += 1
    return CodePointIndex._from_validated(index)


def byte_offset_of(text: StringSlice, index: CodePointIndex) raises -> ByteOffset:
    """Convert a Unicode code-point index to a UTF-8 byte offset.

    The index at the final endpoint is valid. Raises when `index` is past that
    endpoint; every in-bounds code-point index has exactly one byte offset.
    """
    var target = index.value()
    var current_index = 0
    var byte_offset = 0
    for code_point in text.codepoints():
        if current_index == target:
            return ByteOffset._from_validated(byte_offset)
        byte_offset += code_point.utf8_byte_length()
        current_index += 1
    if current_index == target:
        return ByteOffset._from_validated(byte_offset)
    raise Error(
        String(
            "code-point index ",
            target,
            " is past final endpoint ",
            current_index,
        )
    )


def count_code_points(text: StringSlice) -> Int:
    """Return the total number of Unicode code points in UTF-8 `text`.

    This operation is total and does not raise. It counts code points rather
    than bytes or extended grapheme clusters.
    """
    return len(text.codepoints())


def floor_utf8_boundary(text: StringSlice, byte_offset: Int) -> ByteOffset:
    """Snap a raw UTF-8 byte offset down to the nearest code-point boundary.

    This operation is total and does not raise: negative offsets become zero,
    offsets past the byte length clamp to the final endpoint, and interior
    offsets snap to the containing code point's start.
    """
    return ByteOffset._from_validated(_floor_utf8_boundary_index(text, byte_offset))


def byte_ranges_of_code_points(
    text: StringSlice, positions: Span[Int, _]
) raises -> List[ByteRange]:
    """Map strictly increasing code-point positions to merged byte ranges.

    Each position is a zero-based Unicode code-point index into `text`. Runs of
    consecutive positions merge into one half-open UTF-8 `ByteRange`, while
    gaps remain discontiguous. Raises when a position is negative or outside
    the text's code-point count, or when adjacent positions are not strictly
    increasing. An empty span returns an empty list.
    """
    var ranges = List[ByteRange]()
    if len(positions) == 0:
        return ranges^

    for position_index in range(len(positions)):
        var position = positions[position_index]
        if position < 0:
            raise Error(
                String(
                    "code-point index ",
                    position,
                    " at position ",
                    position_index,
                    " must be nonnegative",
                )
            )
        if position_index > 0:
            var previous = positions[position_index - 1]
            if previous >= position:
                raise Error(
                    String(
                        "code-point positions must be strictly increasing: positions ",
                        position_index - 1,
                        " and ",
                        position_index,
                        " contain ",
                        previous,
                        " and ",
                        position,
                    )
                )

    var target_index = 0
    var code_point_index = 0
    var byte_offset = 0
    var run_start = -1
    for code_point in text.codepoints():
        if (
            target_index < len(positions)
            and positions[target_index] == code_point_index
        ):
            if run_start < 0:
                run_start = byte_offset
            target_index += 1
        elif run_start >= 0:
            ranges.append(ByteRange._from_validated(run_start, byte_offset))
            run_start = -1

        byte_offset += code_point.utf8_byte_length()
        code_point_index += 1

    if run_start >= 0:
        ranges.append(ByteRange._from_validated(run_start, byte_offset))

    if target_index < len(positions):
        raise Error(
            String(
                "code-point index ",
                positions[target_index],
                " is outside text code-point count ",
                code_point_index,
            )
        )
    return ranges^
