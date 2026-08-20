"""Validated byte ranges and UTF-8-boundary-safe slicing."""

from .position import ByteOffset


struct ByteRange(Copyable, Equatable):
    """A validated half-open range of byte offsets.

    `start()` is inclusive and `end()` is exclusive. Construction establishes
    `0 <= start() <= end()`, but a range is not tied to a particular string
    until it is passed to `validate_text_range()` or `slice_text()`. Reads trust
    that invariant thereafter. Direct mutation of underscore-prefixed storage
    is out of contract; call `validate()` explicitly after unusual low-level
    mutation when a checkpoint is needed.
    """

    var _start: Int
    var _end: Int

    def __init__(out self, start: Int, end: Int) raises:
        if start < 0:
            raise Error("byte range start must be nonnegative")
        if end < start:
            raise Error("byte range end must not precede start")
        self._start = start
        self._end = end

    def __init__(out self, start: ByteOffset, end: ByteOffset) raises:
        var start_value = start.value()
        var end_value = end.value()
        if end_value < start_value:
            raise Error("byte range end must not precede start")
        self._start = start_value
        self._end = end_value

    def validate(self) raises:
        """Validate the stored endpoints explicitly."""
        if self._start < 0:
            raise Error("byte range start must be nonnegative")
        if self._end < self._start:
            raise Error("byte range end must not precede start")

    def start(self) -> Int:
        """Return the inclusive byte offset."""
        return self._start

    def end(self) -> Int:
        """Return the exclusive byte offset."""
        return self._end

    def __eq__(self, other: Self) -> Bool:
        return self._start == other._start and self._end == other._end

    def byte_length(self) -> Int:
        """Return the number of bytes in the range."""
        return self._end - self._start

    def is_empty(self) -> Bool:
        """Return whether the range contains no bytes."""
        return self._start == self._end

    def contains(self, byte_offset: Int) -> Bool:
        """Return whether `byte_offset` is inside this half-open range."""
        return byte_offset >= self._start and byte_offset < self._end


def is_utf8_boundary(text: StringSlice, byte_offset: Int) -> Bool:
    """Return whether an offset is a valid UTF-8 code-point boundary.

    The start and exclusive end of `text` are boundaries. Negative offsets,
    offsets past the end, and offsets on UTF-8 continuation bytes are not.

    This wrapper relies on `StringSlice`'s UTF-8 invariant and delegates valid
    offsets to its standard-library `is_codepoint_boundary()` operation. It
    adds total behavior for application indexing: out-of-bounds offsets return
    `False` instead of reaching the standard-library bounds assertion. It does
    not accept or validate an arbitrary byte buffer.
    """
    var byte_length = text.byte_length()
    if byte_offset < 0 or byte_offset > byte_length:
        return False
    return text.is_codepoint_boundary(byte_offset)


def validate_text_range(text: StringSlice, byte_range: ByteRange) raises:
    """Validate that a byte range is in bounds and does not split UTF-8.

    This validates code-point boundaries, not grapheme-cluster boundaries.
    Splitting between a base character and a combining mark is therefore safe
    at the UTF-8 storage layer even when it is unsuitable for presentation.
    """
    if byte_range.end() > text.byte_length():
        raise Error("byte range is outside the text")
    if not is_utf8_boundary(text, byte_range.start()):
        raise Error("byte range start splits a UTF-8 code point")
    if not is_utf8_boundary(text, byte_range.end()):
        raise Error("byte range end splits a UTF-8 code point")


def slice_text(text: StringSlice, byte_range: ByteRange) raises -> String:
    """Copy a validated half-open byte range from UTF-8 text.

    Raises when the range is out of bounds or either endpoint is inside a
    multi-byte code point.
    """
    validate_text_range(text, byte_range)
    return String(text[byte = byte_range.start() : byte_range.end()])
