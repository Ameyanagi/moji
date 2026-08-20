"""Validated byte ranges and UTF-8-boundary-safe slicing."""


struct ByteRange(Copyable, Equatable):
    """A validated half-open range of byte offsets.

    `start()` is inclusive and `end()` is exclusive. Construction and semantic
    access guarantee `0 <= start() <= end()`, but a range is not tied to a
    particular string until it is passed to `validate_text_range()` or
    `slice_text()`.
    """

    # Mojo 1.0 does not enforce private struct fields. Store a start hint and a
    # length hint so every possible pair of Int field values normalizes to a
    # valid semantic range, even if external code ignores underscore convention.
    var _start_hint: Int
    var _length_hint: Int

    def __init__(out self, start: Int, end: Int) raises:
        if start < 0:
            raise Error("byte range start must be nonnegative")
        if end < start:
            raise Error("byte range end must not precede start")
        self._start_hint = start
        self._length_hint = end - start

    def _normalized_start(self) -> Int:
        return max(self._start_hint, 0)

    def _normalized_length(self) -> Int:
        var start = self._normalized_start()
        if self._length_hint <= 0:
            return 0
        return min(self._length_hint, Int.MAX - start)

    def start(self) -> Int:
        """Return the inclusive byte offset."""
        return self._normalized_start()

    def end(self) -> Int:
        """Return the exclusive byte offset."""
        return self._normalized_start() + self._normalized_length()

    def __eq__(self, other: Self) -> Bool:
        return self.start() == other.start() and self.end() == other.end()

    def byte_length(self) -> Int:
        """Return the number of bytes in the range."""
        return self._normalized_length()

    def is_empty(self) -> Bool:
        """Return whether the range contains no bytes."""
        return self._normalized_length() == 0

    def contains(self, byte_offset: Int) -> Bool:
        """Return whether `byte_offset` is inside this half-open range."""
        return byte_offset >= self.start() and byte_offset < self.end()


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
