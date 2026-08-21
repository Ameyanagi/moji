"""Validated byte ranges and UTF-8-boundary-safe slicing."""

from std.io import Writable, Writer

from .position import ByteOffset


struct _Validated:
    def __init__(out self):
        pass


struct ByteRange(Copyable, Equatable, ImplicitlyCopyable, Writable):
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
            raise Error(String("byte range start must be nonnegative, got ", start))
        if end < start:
            raise Error(
                String("byte range end ", end, " must not precede start ", start)
            )
        self._start = start
        self._end = end

    def __init__(out self, start: ByteOffset, end: ByteOffset) raises:
        var start_value = start.value()
        var end_value = end.value()
        if end_value < start_value:
            raise Error(
                String(
                    "byte range end ",
                    end_value,
                    " must not precede start ",
                    start_value,
                )
            )
        self._start = start_value
        self._end = end_value

    @staticmethod
    def _from_validated(start: Int, end: Int) -> ByteRange:
        """Construct a byte range whose ordered nonnegative ends are trusted."""
        return ByteRange(start, end, _validated=_Validated())

    def __init__(out self, start: Int, end: Int, *, _validated: _Validated):
        self._start = start
        self._end = end

    @staticmethod
    def at(start: Int, length: Int) raises -> ByteRange:
        """Construct the byte range from `start` through `start + length`.

        Both arguments are measured in UTF-8 bytes. Raises when `start` or
        `length` is negative; otherwise construction cannot fail.
        """
        if start < 0:
            raise Error(String("byte range start must be nonnegative, got ", start))
        if length < 0:
            raise Error(String("byte range length must be nonnegative, got ", length))
        return ByteRange._from_validated(start, start + length)

    @staticmethod
    def empty_at(offset: Int) raises -> ByteRange:
        """Construct an empty byte range at `offset`.

        `offset` is measured in UTF-8 bytes. Raises when `offset` is negative;
        otherwise construction cannot fail.
        """
        if offset < 0:
            raise Error(String("byte range offset must be nonnegative, got ", offset))
        return ByteRange._from_validated(offset, offset)

    @staticmethod
    def up_to(end: Int) raises -> ByteRange:
        """Construct the byte range from zero through `end`.

        `end` is an exclusive UTF-8 byte offset. Raises when `end` is negative;
        otherwise construction cannot fail.
        """
        if end < 0:
            raise Error(String("byte range end must be nonnegative, got ", end))
        return ByteRange._from_validated(0, end)

    def validate(self) raises:
        """Validate the stored endpoints explicitly."""
        if self._start < 0:
            raise Error(
                String("byte range start must be nonnegative, got ", self._start)
            )
        if self._end < self._start:
            raise Error(
                String(
                    "byte range end ",
                    self._end,
                    " must not precede start ",
                    self._start,
                )
            )

    def start(self) -> Int:
        """Return the inclusive byte offset."""
        return self._start

    def end(self) -> Int:
        """Return the exclusive byte offset."""
        return self._end

    def write_to[W: Writer](self, mut writer: W):
        """Write the half-open byte range as `start..end`."""
        writer.write(self._start, "..", self._end)

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

    def contains_range(self, other: ByteRange) -> Bool:
        """Return whether this byte range contains all of `other`.

        Endpoints are UTF-8 byte offsets. This operation is total and does not
        raise; an empty `other` at either boundary is contained.
        """
        return self._start <= other._start and other._end <= self._end

    def intersect(self, other: ByteRange) -> Optional[ByteRange]:
        """Return the half-open intersection of two byte ranges.

        Endpoints are UTF-8 byte offsets. This operation is total and does not
        raise. Ranges separated by a gap return `None`; touching ranges return
        an empty range at their shared boundary.
        """
        var start = max(self._start, other._start)
        var end = min(self._end, other._end)
        if end < start:
            return None
        return ByteRange._from_validated(start, end)

    def cover(self, other: ByteRange) -> ByteRange:
        """Return the smallest byte range containing both ranges.

        Endpoints are UTF-8 byte offsets. This operation is total and does not
        raise because covering validated ranges preserves their invariant.
        """
        return ByteRange._from_validated(
            min(self._start, other._start), max(self._end, other._end)
        )

    def shifted(self, delta: Int) raises -> ByteRange:
        """Shift both byte endpoints by `delta` UTF-8 bytes.

        Raises only when shifting would make the start negative. After that
        check, shifting an already-valid range preserves its ordering and does
        not otherwise fail.
        """
        var start = self._start + delta
        if start < 0:
            raise Error(
                String(
                    "shifted byte range start must be nonnegative, got ",
                    start,
                )
            )
        return ByteRange._from_validated(start, self._end + delta)


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


def _floor_utf8_boundary_index(text: StringSlice, byte_offset: Int) -> Int:
    """Return a clamped byte offset snapped down to a UTF-8 boundary."""
    var boundary = min(max(byte_offset, 0), text.byte_length())
    while boundary > 0 and not text.is_codepoint_boundary(boundary):
        boundary -= 1
    return boundary


def _code_point_label_at(text: StringSlice, byte_offset: Int) -> String:
    """Return the `U+XXXX` label at a trusted UTF-8 byte boundary."""
    var digits = hex(ord(text[byte=byte_offset]), prefix="").upper()
    while digits.byte_length() < 4:
        digits = String("0", digits)
    return String("U+", digits)


def _utf8_boundary_error_message(text: StringSlice, byte_offset: Int) -> String:
    """Describe a trusted in-bounds offset that splits a UTF-8 code point."""
    var start = _floor_utf8_boundary_index(text, byte_offset)
    var end = start + text[byte=start].byte_length()
    return String(
        "byte offset ",
        byte_offset,
        " splits ",
        _code_point_label_at(text, start),
        "; nearest boundaries are ",
        start,
        " and ",
        end,
    )


def validate_text_range(text: StringSlice, byte_range: ByteRange) raises:
    """Validate that a byte range is in bounds and does not split UTF-8.

    This validates code-point boundaries, not grapheme-cluster boundaries.
    Splitting between a base character and a combining mark is therefore safe
    at the UTF-8 storage layer even when it is unsuitable for presentation.
    """
    if byte_range.end() > text.byte_length():
        raise Error(
            String(
                "byte range end ",
                byte_range.end(),
                " is outside text byte length ",
                text.byte_length(),
            )
        )
    if not is_utf8_boundary(text, byte_range.start()):
        raise Error(_utf8_boundary_error_message(text, byte_range.start()))
    if not is_utf8_boundary(text, byte_range.end()):
        raise Error(_utf8_boundary_error_message(text, byte_range.end()))


def slice_text(text: StringSlice, byte_range: ByteRange) raises -> String:
    """Copy a validated half-open byte range from UTF-8 text.

    Raises when the range is out of bounds or either endpoint is inside a
    multi-byte code point.
    """
    validate_text_range(text, byte_range)
    return String(text[byte = byte_range.start() : byte_range.end()])
