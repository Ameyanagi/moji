"""Owned immutable indexing of the standard-library grapheme boundaries."""

from .byte_range import ByteRange
from .grapheme import _grapheme_boundary_error_message
from .position import ByteOffset, GraphemeIndex
from std.collections import List


struct GraphemeBoundaryIndex(Copyable, Equatable):
    """Own text and cache every grapheme boundary, including both endpoints.

    Pass a String with `^` to transfer ownership without copying its bytes.
    Construction takes O(bytes) time and O(clusters) offset storage. Exact
    cluster-to-byte queries take O(1); byte-to-cluster queries take O(log n).
    Reads never resegment the text. There are no mutating public operations:
    construct a new index after editing text. Underscore fields are private by
    convention; direct mutation is out of contract, with `validate()` available
    as an explicit checkpoint.

    Segmentation follows the pinned Mojo 1.0.0 standard library, checked against
    Unicode 17.0.0 GraphemeBreakTest; see docs/compatibility.md for its profile.
    """

    var _text: String
    var _byte_offsets: List[Int]

    def __init__(out self, var text: String):
        self._text = text^
        self._byte_offsets = List[Int](length=1, fill=0)
        var offset = 0
        for cluster in self._text.graphemes():
            offset += cluster.byte_length()
            self._byte_offsets.append(offset)

    def text(self) -> StringSlice[origin_of(self._text)]:
        """Borrow the indexed text without a copy; its lifetime follows self."""
        return StringSlice(self._text)

    def byte_length(self) -> Int:
        return self._text.byte_length()

    def grapheme_count(self) -> Int:
        return len(self._byte_offsets) - 1

    def byte_offset(self, index: GraphemeIndex) raises -> ByteOffset:
        """Map a cluster index, including the final endpoint, in O(1)."""
        var target = index.value()
        if target > self.grapheme_count():
            raise Error(
                String(
                    "grapheme index ",
                    target,
                    " is past final endpoint ",
                    self.grapheme_count(),
                )
            )
        return ByteOffset._from_validated(self._byte_offsets[target])

    def grapheme_index(self, offset: ByteOffset) raises -> GraphemeIndex:
        """Map an exact byte boundary, including the final endpoint, in O(log n).

        Interior UTF-8 bytes and scalar boundaries inside a cluster are errors;
        this operation never silently snaps a cursor to a different boundary.
        """
        var target = offset.value()
        if target > self.byte_length():
            raise Error(
                String(
                    "byte offset ",
                    target,
                    " is outside text byte length ",
                    self.byte_length(),
                )
            )
        var lower = 0
        var upper = len(self._byte_offsets)
        while lower < upper:
            var middle = lower + (upper - lower) // 2
            if self._byte_offsets[middle] < target:
                lower = middle + 1
            else:
                upper = middle
        if self._byte_offsets[lower] != target:
            raise Error(
                _grapheme_boundary_error_message(
                    target, self._byte_offsets[lower - 1], self._byte_offsets[lower]
                )
            )
        return GraphemeIndex._from_validated(lower)

    def byte_range(self, start: GraphemeIndex, end: GraphemeIndex) raises -> ByteRange:
        """Map a half-open cluster range in O(1); empty endpoint ranges are valid."""
        if start.value() > end.value():
            raise Error(
                String(
                    "grapheme range start ",
                    start.value(),
                    " must not exceed end ",
                    end.value(),
                )
            )
        var start_byte = self.byte_offset(start)
        var end_byte = self.byte_offset(end)
        return ByteRange._from_validated(start_byte.value(), end_byte.value())

    def slice(
        self, start: GraphemeIndex, end: GraphemeIndex
    ) raises -> StringSlice[origin_of(self._text)]:
        """Borrow a half-open cluster range with O(1) boundary lookup, no copy."""
        var span = self.byte_range(start, end)
        return StringSlice(self._text)[byte = span.start() : span.end()]

    def validate(self) raises:
        """Resegment and verify all owned boundaries after unusual low-level use."""
        if len(self._byte_offsets) == 0 or self._byte_offsets[0] != 0:
            raise Error("grapheme boundary table must contain initial byte offset 0")
        var boundary = 1
        var offset = 0
        for cluster in self._text.graphemes():
            offset += cluster.byte_length()
            if boundary >= len(self._byte_offsets):
                raise Error(
                    String("grapheme boundary table is missing endpoint ", boundary)
                )
            if self._byte_offsets[boundary] != offset:
                raise Error(
                    String(
                        "grapheme boundary ",
                        boundary,
                        " has byte offset ",
                        self._byte_offsets[boundary],
                        "; expected ",
                        offset,
                    )
                )
            boundary += 1
        if boundary != len(self._byte_offsets):
            raise Error(
                String(
                    "grapheme boundary table has ",
                    len(self._byte_offsets),
                    " entries; expected ",
                    boundary,
                )
            )

    def __eq__(self, other: Self) -> Bool:
        # Constructor-established boundaries are a pure function of owned text.
        return self._text == other._text
