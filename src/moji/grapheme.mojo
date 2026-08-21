"""Extended-grapheme conversion, slicing, and borrowed span iteration."""

from .byte_range import ByteRange
from .position import ByteOffset, GraphemeIndex
from std.collections.string import GraphemeSliceIter


def _grapheme_boundary_error_message(
    byte_offset: Int, cluster_start: Int, cluster_end: Int
) -> String:
    """Describe an in-bounds byte offset inside one grapheme cluster."""
    return String(
        "byte offset ",
        byte_offset,
        " is inside a grapheme cluster; nearest boundaries are ",
        cluster_start,
        " and ",
        cluster_end,
    )


def grapheme_index(text: StringSlice, offset: ByteOffset) raises -> GraphemeIndex:
    """Convert a UTF-8 byte offset to an extended-grapheme index.

    The final byte endpoint maps to `count_graphemes(text)`. Raises when the
    offset is past the UTF-8 byte length or is not a boundary between extended
    grapheme clusters according to the standard-library segmentation.
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

    var index = 0
    var cluster_start = 0
    for cluster in text.graphemes():
        if target == cluster_start:
            return GraphemeIndex._from_validated(index)
        var cluster_end = cluster_start + cluster.byte_length()
        if target < cluster_end:
            raise Error(
                _grapheme_boundary_error_message(target, cluster_start, cluster_end)
            )
        cluster_start = cluster_end
        index += 1
    return GraphemeIndex._from_validated(index)


def byte_range_of_grapheme(text: StringSlice, index: GraphemeIndex) raises -> ByteRange:
    """Return one extended grapheme cluster's half-open UTF-8 byte range.

    `index` is measured in extended grapheme clusters according to the
    standard-library segmentation. Raises when `index` is greater than or
    equal to the cluster count; unlike `grapheme_index`, the final endpoint is
    not an element index.
    """
    var target = index.value()
    var current_index = 0
    var cluster_start = 0
    for cluster in text.graphemes():
        var cluster_end = cluster_start + cluster.byte_length()
        if current_index == target:
            return ByteRange._from_validated(cluster_start, cluster_end)
        cluster_start = cluster_end
        current_index += 1
    raise Error(
        String(
            "grapheme index ",
            target,
            " is outside grapheme cluster count ",
            current_index,
        )
    )


def count_graphemes(text: StringSlice) -> Int:
    """Return the number of extended grapheme clusters in UTF-8 `text`.

    This operation is total and non-raising. Cluster boundaries follow the
    standard-library `StringSlice.graphemes()` segmentation.
    """
    return len(text.graphemes())


def slice_graphemes(
    text: StringSlice, start: GraphemeIndex, end: GraphemeIndex
) raises -> String:
    """Copy the extended grapheme clusters in the half-open range `[start, end)`.

    Both endpoints are measured in extended grapheme clusters according to the
    standard-library segmentation. Raises when `start > end` or when `end` is
    greater than the cluster count. Equal endpoints return an empty string.
    """
    var start_index = start.value()
    var end_index = end.value()
    if start_index > end_index:
        raise Error(
            String(
                "grapheme slice start ",
                start_index,
                " must not exceed end ",
                end_index,
            )
        )

    var cluster_count = count_graphemes(text)
    if end_index > cluster_count:
        raise Error(
            String(
                "grapheme slice end ",
                end_index,
                " is outside grapheme cluster count ",
                cluster_count,
            )
        )

    var current_index = 0
    var byte_offset = 0
    var start_byte = 0
    for cluster in text.graphemes():
        if current_index == start_index:
            start_byte = byte_offset
        if current_index == end_index:
            return String(text[byte=start_byte:byte_offset])
        byte_offset += cluster.byte_length()
        current_index += 1

    if start_index == cluster_count:
        start_byte = byte_offset
    return String(text[byte=start_byte:byte_offset])


struct GraphemeSpan[mut: Bool, //, origin: Origin[mut=mut]](Copyable, Equatable):
    """A borrowed extended grapheme cluster and its UTF-8 byte range."""

    var _byte_range: ByteRange
    var _text: StringSlice[Self.origin]

    def __init__(out self, byte_range: ByteRange, text: StringSlice[Self.origin]):
        self._byte_range = byte_range
        self._text = text

    def byte_range(self) -> ByteRange:
        """Return the cluster's half-open UTF-8 byte range in its source."""
        return self._byte_range

    def text(self) -> StringSlice[Self.origin]:
        """Return a borrowed view of the extended grapheme cluster."""
        return self._text

    def __eq__(self, other: Self) -> Bool:
        return self._byte_range == other._byte_range and self._text == other._text


struct GraphemeSpanIterator[mut: Bool, //, origin: Origin[mut=mut]](
    Copyable, Iterable, Iterator
):
    """Iterate over borrowed grapheme clusters with source byte ranges."""

    comptime IteratorType[
        iterable_mut: Bool, //, iterable_origin: Origin[mut=iterable_mut]
    ]: Iterator = Self
    comptime Element = GraphemeSpan[Self.origin]

    var _graphemes: GraphemeSliceIter[Self.origin]
    var _byte_offset: Int

    def __init__(out self, text: StringSlice[Self.origin]):
        self._graphemes = text.graphemes()
        self._byte_offset = 0

    def __iter__(ref self) -> Self.IteratorType[origin_of(self)]:
        return self.copy()

    def __next__(mut self) raises StopIteration -> GraphemeSpan[Self.origin]:
        var cluster = self._graphemes.__next__()
        var start = self._byte_offset
        self._byte_offset += cluster.byte_length()
        return GraphemeSpan[Self.origin](
            ByteRange._from_validated(start, self._byte_offset), cluster
        )


def grapheme_spans[
    mut: Bool, //, origin: Origin[mut=mut]
](text: StringSlice[origin]) -> GraphemeSpanIterator[origin]:
    """Return a non-raising iterator over borrowed extended grapheme spans.

    Spans are yielded in source order. Their half-open ranges use UTF-8 byte
    offsets, and their borrowed text follows standard-library grapheme
    segmentation while retaining the source slice's origin.
    """
    return GraphemeSpanIterator[origin](text)
