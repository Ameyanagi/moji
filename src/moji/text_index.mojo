"""Owned UTF-8 scalar index and exact transformed-to-source mappings."""

from .byte_range import ByteRange, validate_text_range
from .conversion import _utf8_boundary_error_message
from .position import ByteOffset, CodePointIndex
from std.collections import List, Span


comptime _SORTED_UNION_THRESHOLD = 64


struct _SourceRangeEntry(Copyable):
    var range: ByteRange
    var encounter_index: Int

    def __init__(out self, range: ByteRange, encounter_index: Int):
        self.range = range
        self.encounter_index = encounter_index


struct _SourceUnionComponent(Copyable):
    var range: ByteRange
    var first_encounter: Int

    def __init__(out self, range: ByteRange, first_encounter: Int):
        self.range = range
        self.first_encounter = first_encounter


def _source_entry_precedes(left: _SourceRangeEntry, right: _SourceRangeEntry) -> Bool:
    if left.range.start() != right.range.start():
        return left.range.start() < right.range.start()
    if left.range.end() != right.range.end():
        return left.range.end() < right.range.end()
    return left.encounter_index < right.encounter_index


def _sift_source_entry_heap(mut entries: List[_SourceRangeEntry], root: Int, end: Int):
    var current = root
    while True:
        var child = 2 * current + 1
        if child > end:
            return
        if child + 1 <= end and _source_entry_precedes(
            entries[child], entries[child + 1]
        ):
            child += 1
        if not _source_entry_precedes(entries[current], entries[child]):
            return
        var temporary = entries[current].copy()
        entries[current] = entries[child].copy()
        entries[child] = temporary^
        current = child


def _sort_source_entries(mut entries: List[_SourceRangeEntry]):
    if len(entries) < 2:
        return
    var root = len(entries) // 2
    while root > 0:
        root -= 1
        _sift_source_entry_heap(entries, root, len(entries) - 1)
    var end = len(entries) - 1
    while end > 0:
        var temporary = entries[0].copy()
        entries[0] = entries[end].copy()
        entries[end] = temporary^
        end -= 1
        _sift_source_entry_heap(entries, 0, end)


def _sorted_exact_source_union(
    mut entries: List[_SourceRangeEntry], selected_count: Int
) -> List[ByteRange]:
    """Build an exact union in earliest-contributor order in O(k log k)."""
    _sort_source_entries(entries)
    var components = List[_SourceUnionComponent](capacity=len(entries))
    for entry_index in range(len(entries)):
        var entry = entries[entry_index].copy()
        if len(components) == 0:
            components.append(_SourceUnionComponent(entry.range, entry.encounter_index))
            continue
        var last_index = len(components) - 1
        var last = components[last_index].copy()
        if (
            entry.range.start() <= last.range.end()
            and last.range.start() <= entry.range.end()
        ):
            var first_encounter = last.first_encounter
            if entry.encounter_index < first_encounter:
                first_encounter = entry.encounter_index
            components[last_index] = _SourceUnionComponent(
                last.range.cover(entry.range), first_encounter
            )
        else:
            components.append(_SourceUnionComponent(entry.range, entry.encounter_index))

    # First-contributor ordinals are unique component keys. A dense lookup emits
    # encounter order in one pass without a second comparison sort.
    var component_at_encounter = List[Int](capacity=selected_count)
    for _ in range(selected_count):
        component_at_encounter.append(-1)
    for component_index in range(len(components)):
        component_at_encounter[
            components[component_index].first_encounter
        ] = component_index
    var result = List[ByteRange](capacity=len(components))
    for encounter_index in range(selected_count):
        var component_index = component_at_encounter[encounter_index]
        if component_index >= 0:
            result.append(components[component_index].range)
    return result^


def _append_exact_source_range(
    mut ranges: List[ByteRange],
    next_range: ByteRange,
    mut source_ordered: Bool,
):
    """Append one range and retain an exact disjoint union in encounter order.

    Monotonic mappings use the final union range as an amortized constant-time
    fast path. Once a discontiguous mapping moves backwards in source order, the
    general encounter-order scan preserves the documented result ordering.
    """
    if source_ordered and len(ranges) > 0:
        var last_index = len(ranges) - 1
        var last = ranges[last_index]
        if last.end() < next_range.start():
            ranges.append(next_range)
            return
        if next_range.end() >= last.start():
            var merged_last = last.cover(next_range)
            ranges[last_index] = merged_last
            # A bridge may connect the final range to earlier sorted ranges.
            while last_index > 0:
                var previous = ranges[last_index - 1]
                if (
                    merged_last.start() > previous.end()
                    or previous.start() > merged_last.end()
                ):
                    break
                merged_last = merged_last.cover(previous)
                _ = ranges.pop(last_index)
                last_index -= 1
                ranges[last_index] = merged_last
            return
        # This range precedes the final discontiguous range. Preserve encounter
        # order from here onward with the fully general path.
        source_ordered = False

    var merged = next_range
    var first_overlap = -1
    var index = 0
    while index < len(ranges):
        var current = ranges[index]
        if merged.start() <= current.end() and current.start() <= merged.end():
            merged = merged.cover(current)
            if first_overlap < 0:
                first_overlap = index
                ranges[index] = merged
                index += 1
            else:
                _ = ranges.pop(index)
                ranges[first_overlap] = merged
        else:
            index += 1
    if first_overlap < 0:
        ranges.append(next_range)


struct TextIndex(Copyable):
    """Own text and index every Unicode code-point boundary once.

    ASCII text uses identity byte/code-point coordinates and retains no offset
    table. Non-ASCII text retains one byte offset per code-point boundary,
    including the final endpoint. Construction is linear in the input size;
    code-point-to-byte queries are constant time and byte-to-code-point queries
    use binary search. This value is useful when the same text is queried more
    than once; one-off conversion functions remain the smaller API for one-off
    work.
    """

    var _text: String
    var _byte_offsets: List[Int]
    var _code_point_count: Int
    var _is_ascii: Bool

    def __init__(out self, text: StringSlice):
        self._text = String(text)
        self._byte_offsets = List[Int]()
        self._code_point_count = 0
        self._is_ascii = True

        var byte_offset = 0
        for scalar in self._text.codepoints():
            var scalar_bytes = scalar.utf8_byte_length()
            if self._is_ascii and scalar_bytes != 1:
                self._is_ascii = False
                # Every preceding ASCII boundary is its own integer coordinate.
                for ascii_offset in range(self._code_point_count + 1):
                    self._byte_offsets.append(ascii_offset)
            byte_offset += scalar_bytes
            self._code_point_count += 1
            if not self._is_ascii:
                self._byte_offsets.append(byte_offset)

    def text(self) -> String:
        """Return an owned copy of the indexed text."""
        return String(self._text)

    def validate(self) raises:
        """Recheck index storage after unusual direct low-level mutation.

        Normal methods trust constructor-established invariants. Mojo 1.0 does
        not enforce field privacy, so this explicit checkpoint verifies every
        stored boundary against the owned text when low-level code has touched
        underscore-prefixed fields.
        """
        if self._code_point_count < 0:
            raise Error("indexed code-point count must be nonnegative")
        if self._is_ascii and len(self._byte_offsets) != 0:
            raise Error("ASCII index must not retain a byte-offset table")
        if not self._is_ascii and len(self._byte_offsets) != self._code_point_count + 1:
            raise Error(
                "non-ASCII byte-offset table length does not match code-point count"
            )
        if not self._is_ascii and self._byte_offsets[0] != 0:
            raise Error("non-ASCII byte-offset table must begin at zero")

        var actual_count = 0
        var actual_byte_offset = 0
        var actual_ascii = True
        for scalar in self._text.codepoints():
            var scalar_bytes = scalar.utf8_byte_length()
            actual_ascii = actual_ascii and scalar_bytes == 1
            actual_byte_offset += scalar_bytes
            actual_count += 1
            if (
                not self._is_ascii
                and self._byte_offsets[actual_count] != actual_byte_offset
            ):
                raise Error(
                    String(
                        "byte-offset table differs from text at code-point endpoint ",
                        actual_count,
                    )
                )
        if actual_count != self._code_point_count:
            raise Error("indexed code-point count differs from owned text")
        if actual_ascii != self._is_ascii:
            raise Error("indexed ASCII classification differs from owned text")

    def is_ascii(self) -> Bool:
        """Return whether every indexed scalar is one-byte ASCII."""
        return self._is_ascii

    def byte_length(self) -> Int:
        """Return the indexed text length in UTF-8 bytes."""
        return self._text.byte_length()

    def code_point_count(self) -> Int:
        """Return the indexed text length in Unicode code points."""
        return self._code_point_count

    def byte_offset(self, index: CodePointIndex) raises -> ByteOffset:
        """Map a code-point index, including the endpoint, to a byte offset."""
        var target = index.value()
        if target > self._code_point_count:
            raise Error(
                String(
                    "code-point index ",
                    target,
                    " is past final endpoint ",
                    self._code_point_count,
                )
            )
        if self._is_ascii:
            return ByteOffset._from_validated(target)
        return ByteOffset._from_validated(self._byte_offsets[target])

    def code_point_index(self, offset: ByteOffset) raises -> CodePointIndex:
        """Map a boundary byte offset, including the endpoint, to an index."""
        var target = offset.value()
        var byte_length = self._text.byte_length()
        if target > byte_length:
            raise Error(
                String(
                    "byte offset ",
                    target,
                    " is outside text byte length ",
                    byte_length,
                )
            )
        if self._is_ascii:
            return CodePointIndex._from_validated(target)
        var lower = 0
        var upper = len(self._byte_offsets)
        while lower < upper:
            var middle = lower + (upper - lower) // 2
            if self._byte_offsets[middle] < target:
                lower = middle + 1
            else:
                upper = middle
        if self._byte_offsets[lower] != target:
            raise Error(_utf8_boundary_error_message(self._text, target))
        return CodePointIndex._from_validated(lower)

    def byte_range(
        self, start: CodePointIndex, end: CodePointIndex
    ) raises -> ByteRange:
        """Map a half-open code-point range to its exact UTF-8 byte range."""
        var start_index = start.value()
        var end_index = end.value()
        if end_index < start_index:
            raise Error(
                String(
                    "code-point range end ",
                    end_index,
                    " must not precede start ",
                    start_index,
                )
            )
        var start_offset = self.byte_offset(start).value()
        var end_offset = self.byte_offset(end).value()
        return ByteRange._from_validated(start_offset, end_offset)

    def byte_ranges_of_code_points(
        self, positions: Span[Int, _]
    ) raises -> List[ByteRange]:
        """Map increasing code-point positions to merged UTF-8 ranges.

        Unlike the one-off free function, this method never scans the text. It
        validates positions, performs indexed boundary lookups, and merges only
        consecutive code-point positions.
        """
        var ranges = List[ByteRange]()
        if len(positions) == 0:
            return ranges^

        self._validate_code_point_positions(positions)
        var run_start_index = positions[0]
        for position_index in range(1, len(positions)):
            var position = positions[position_index]
            var previous = positions[position_index - 1]
            if position != previous + 1:
                ranges.append(
                    self.byte_range(
                        CodePointIndex._from_validated(run_start_index),
                        CodePointIndex._from_validated(previous + 1),
                    )
                )
                run_start_index = position

        ranges.append(
            self.byte_range(
                CodePointIndex._from_validated(run_start_index),
                CodePointIndex._from_validated(positions[len(positions) - 1] + 1),
            )
        )
        return ranges^

    def _validate_code_point_positions(self, positions: Span[Int, _]) raises:
        """Validate matcher positions without allocating mapped ranges."""
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
            if position >= self._code_point_count:
                raise Error(
                    String(
                        "code-point index ",
                        position,
                        " is outside text code-point count ",
                        self._code_point_count,
                    )
                )
            if position_index > 0:
                var previous = positions[position_index - 1]
                if previous >= position:
                    raise Error(
                        String(
                            (
                                "code-point positions must be strictly increasing:"
                                " positions "
                            ),
                            position_index - 1,
                            " and ",
                            position_index,
                            " contain ",
                            previous,
                            " and ",
                            position,
                        )
                    )


struct MappedText(Copyable):
    """Own transformed text and one exact source range per output scalar.

    A source range must be nonempty and must end on UTF-8 boundaries in the
    owned source text. Repeated ranges model expansion, wider ranges model
    contraction, and arbitrary source order is preserved. Queries accept
    transformed UTF-8 ranges and return their exact source union without
    filling gaps between discontiguous ranges. Union components are ordered by
    the earliest selected transformed position contributing to each component.
    """

    var _source: String
    var _transformed: TextIndex
    var _source_ranges: List[ByteRange]

    def __init__(
        out self,
        source: StringSlice,
        transformed: StringSlice,
        source_ranges: Span[ByteRange, _],
    ) raises:
        self._source = String(source)
        self._transformed = TextIndex(transformed)
        self._source_ranges = List[ByteRange]()

        if len(source_ranges) != self._transformed.code_point_count():
            raise Error(
                String(
                    "mapping count ",
                    len(source_ranges),
                    " must equal transformed code-point count ",
                    self._transformed.code_point_count(),
                )
            )
        for mapping_index in range(len(source_ranges)):
            var source_range = source_ranges[mapping_index]
            if source_range.is_empty():
                raise Error(
                    String(
                        "source range at mapping ", mapping_index, " must be nonempty"
                    )
                )
            validate_text_range(self._source, source_range)
            self._source_ranges.append(source_range)

    def source_text(self) -> String:
        """Return an owned copy of the original source text."""
        return String(self._source)

    def validate(self) raises:
        """Recheck transformed indexing and every source mapping."""
        self._transformed.validate()
        if len(self._source_ranges) != self._transformed.code_point_count():
            raise Error("mapping count differs from transformed code-point count")
        for mapping_index in range(len(self._source_ranges)):
            var source_range = self._source_ranges[mapping_index]
            if source_range.is_empty():
                raise Error(
                    String(
                        "source range at mapping ", mapping_index, " must be nonempty"
                    )
                )
            validate_text_range(self._source, source_range)

    def transformed_text(self) -> String:
        """Return an owned copy of the transformed text."""
        return self._transformed.text()

    def code_point_count(self) -> Int:
        """Return the number of transformed Unicode code points."""
        return self._transformed.code_point_count()

    def source_range_at(self, index: CodePointIndex) raises -> ByteRange:
        """Return the exact source range of one transformed code point."""
        var target = index.value()
        if target >= len(self._source_ranges):
            raise Error(
                String(
                    "transformed code-point index ",
                    target,
                    " is outside element count ",
                    len(self._source_ranges),
                )
            )
        return self._source_ranges[target]

    def _sorted_source_ranges(
        self, start_index: Int, end_index: Int
    ) -> List[ByteRange]:
        var entries = List[_SourceRangeEntry](capacity=end_index - start_index)
        for mapping_index in range(start_index, end_index):
            entries.append(
                _SourceRangeEntry(
                    self._source_ranges[mapping_index], mapping_index - start_index
                )
            )
        return _sorted_exact_source_union(entries, end_index - start_index)

    def _sorted_source_ranges_of_code_points(
        self, positions: Span[Int, _]
    ) -> List[ByteRange]:
        var entries = List[_SourceRangeEntry](capacity=len(positions))
        for encounter_index in range(len(positions)):
            entries.append(
                _SourceRangeEntry(
                    self._source_ranges[positions[encounter_index]], encounter_index
                )
            )
        return _sorted_exact_source_union(entries, len(positions))

    def source_ranges(self, transformed_range: ByteRange) raises -> List[ByteRange]:
        """Map a transformed UTF-8 range to exact source byte ranges.

        The transformed endpoints must be code-point boundaries. Overlapping or
        touching source ranges merge because their union is contiguous; ranges
        separated by any source byte remain distinct, including reordered
        mappings. Each merged component retains the encounter order of its
        earliest contributing transformed position.
        """
        var start_index = self._transformed.code_point_index(
            ByteOffset._from_validated(transformed_range.start())
        ).value()
        var end_index = self._transformed.code_point_index(
            ByteOffset._from_validated(transformed_range.end())
        ).value()
        if end_index < start_index:
            raise Error("transformed range end must not precede start")

        var result = List[ByteRange]()
        var source_ordered = True
        for mapping_index in range(start_index, end_index):
            _append_exact_source_range(
                result, self._source_ranges[mapping_index], source_ordered
            )
            if (
                not source_ordered
                and end_index - start_index >= _SORTED_UNION_THRESHOLD
            ):
                return self._sorted_source_ranges(start_index, end_index)
        return result^

    def source_ranges_of_code_points(
        self, positions: Span[Int, _]
    ) raises -> List[ByteRange]:
        """Map increasing transformed scalar positions to source ranges.

        This is the direct adapter for matcher positions. Position validation
        is identical to `TextIndex.byte_ranges_of_code_points()`, while source
        ranges merge only when their exact union is contiguous. Each merged
        component retains the encounter order of its earliest selected
        transformed position.
        """
        # Validate the complete position set before producing partial output,
        # without allocating transformed ranges that this adapter discards.
        self._transformed._validate_code_point_positions(positions)
        var result = List[ByteRange]()
        var source_ordered = True
        for position in positions:
            _append_exact_source_range(
                result, self._source_ranges[position], source_ordered
            )
            if not source_ordered and len(positions) >= _SORTED_UNION_THRESHOLD:
                return self._sorted_source_ranges_of_code_points(positions)
        return result^
