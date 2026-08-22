from moji import (
    ByteOffset,
    ByteRange,
    CodePointIndex,
    MappedText,
    TextIndex,
    byte_offset_of,
    code_point_index,
)
from std.collections import List
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_ascii_index_uses_identity_coordinates() raises:
    var index = TextIndex("plain ASCII")
    assert_true(index.is_ascii())
    assert_equal(index.byte_length(), 11)
    assert_equal(index.code_point_count(), 11)
    assert_equal(index.byte_offset(CodePointIndex(7)).value(), 7)
    assert_equal(index.code_point_index(ByteOffset(7)).value(), 7)
    assert_true(
        index.byte_range(CodePointIndex(2), CodePointIndex(7)) == ByteRange(2, 7)
    )


def test_unicode_index_matches_scalar_conversions_at_every_endpoint() raises:
    var text = String("Aé北京👨‍👩‍👧‍👦")
    var index = TextIndex(text)
    assert_false(index.is_ascii())
    assert_equal(index.code_point_count(), 12)

    for scalar_index in range(index.code_point_count() + 1):
        var position = CodePointIndex(scalar_index)
        var expected_offset = byte_offset_of(text, position)
        var actual_offset = index.byte_offset(position)
        assert_equal(actual_offset.value(), expected_offset.value())
        assert_equal(
            index.code_point_index(actual_offset).value(),
            code_point_index(text, actual_offset).value(),
        )


def test_unicode_index_rejects_invalid_boundaries_and_endpoints() raises:
    var index = TextIndex("北👍🏽")
    with assert_raises(contains="byte offset 1 splits U+5317"):
        _ = index.code_point_index(ByteOffset(1))
    with assert_raises(contains="byte offset 12 is outside text byte length 11"):
        _ = index.code_point_index(ByteOffset(12))
    with assert_raises(contains="code-point index 4 is past final endpoint 3"):
        _ = index.byte_offset(CodePointIndex(4))


def test_index_validate_rejects_mutated_storage() raises:
    var ascii = TextIndex("abc")
    ascii._code_point_count = 4
    with assert_raises(contains="indexed code-point count differs from owned text"):
        ascii.validate()

    var unicode = TextIndex("北京")
    unicode._byte_offsets[1] = 2
    with assert_raises(contains="differs from text at code-point endpoint 1"):
        unicode.validate()


def test_index_maps_sorted_positions_without_rescanning_text() raises:
    var index = TextIndex("a北京b🇯🇵c")
    var positions: List[Int] = [1, 2, 4, 5]
    var ranges = index.byte_ranges_of_code_points(positions)
    assert_equal(len(ranges), 2)
    assert_true(ranges[0] == ByteRange(1, 7))
    assert_true(ranges[1] == ByteRange(8, 16))

    var duplicate: List[Int] = [1, 1]
    with assert_raises(contains="positions 0 and 1 contain 1 and 1"):
        _ = index.byte_ranges_of_code_points(duplicate)

    var past_end: List[Int] = [7]
    with assert_raises(contains="outside text code-point count 7"):
        _ = index.byte_ranges_of_code_points(past_end)


def test_mapped_text_maps_expansion_back_to_exact_cjk_sources() raises:
    var origins: List[ByteRange] = [
        ByteRange(0, 3),
        ByteRange(0, 3),
        ByteRange(0, 3),
        ByteRange(3, 6),
        ByteRange(3, 6),
        ByteRange(3, 6),
        ByteRange(3, 6),
    ]
    var mapped = MappedText("北京", "beijing", origins)
    assert_equal(mapped.source_text(), "北京")
    assert_equal(mapped.transformed_text(), "beijing")
    assert_equal(mapped.code_point_count(), 7)
    assert_true(mapped.source_range_at(CodePointIndex(4)) == ByteRange(3, 6))

    var ranges = mapped.source_ranges(ByteRange(1, 5))
    assert_equal(len(ranges), 1)
    assert_true(ranges[0] == ByteRange(0, 6))

    var matched_positions: List[Int] = [0, 1, 3, 4]
    var matched_sources = mapped.source_ranges_of_code_points(matched_positions)
    assert_equal(len(matched_sources), 1)
    assert_true(matched_sources[0] == ByteRange(0, 6))


def test_mapped_text_preserves_discontiguous_and_reordered_sources() raises:
    var origins: List[ByteRange] = [ByteRange(4, 5), ByteRange(0, 1)]
    var mapped = MappedText("abcde", "xy", origins)
    var ranges = mapped.source_ranges(ByteRange(0, 2))
    assert_equal(len(ranges), 2)
    assert_true(ranges[0] == ByteRange(4, 5))
    assert_true(ranges[1] == ByteRange(0, 1))

    var matched_positions: List[Int] = [0, 1]
    var matched_sources = mapped.source_ranges_of_code_points(matched_positions)
    assert_equal(len(matched_sources), 2)
    assert_true(matched_sources[0] == ByteRange(4, 5))
    assert_true(matched_sources[1] == ByteRange(0, 1))


def test_mapped_text_merges_transitive_source_range_bridges() raises:
    var origins: List[ByteRange] = [
        ByteRange(0, 2),
        ByteRange(4, 5),
        ByteRange(1, 4),
    ]
    var mapped = MappedText("abcde", "xyz", origins)

    var ranges = mapped.source_ranges(ByteRange(0, 3))
    assert_equal(len(ranges), 1)
    assert_true(ranges[0] == ByteRange(0, 5))

    var matched_positions: List[Int] = [0, 1, 2]
    var matched_sources = mapped.source_ranges_of_code_points(matched_positions)
    assert_equal(len(matched_sources), 1)
    assert_true(matched_sources[0] == ByteRange(0, 5))


def test_mapped_text_merges_bridges_after_reordered_discontiguous_sources() raises:
    var origins: List[ByteRange] = [
        ByteRange(6, 7),
        ByteRange(0, 1),
        ByteRange(3, 4),
        ByteRange(1, 3),
        ByteRange(4, 6),
    ]
    var mapped = MappedText("abcdefg", "vwxyz", origins)

    var ranges = mapped.source_ranges(ByteRange(0, 5))
    assert_equal(len(ranges), 1)
    assert_true(ranges[0] == ByteRange(0, 7))

    var matched_positions: List[Int] = [0, 1, 2, 3, 4]
    var matched_sources = mapped.source_ranges_of_code_points(matched_positions)
    assert_equal(len(matched_sources), 1)
    assert_true(matched_sources[0] == ByteRange(0, 7))


def test_mapped_text_orders_merged_components_by_first_contributor() raises:
    var origins: List[ByteRange] = [
        ByteRange(8, 9),
        ByteRange(4, 5),
        ByteRange(0, 1),
        ByteRange(1, 4),
    ]
    var mapped = MappedText("abcdefghi", "wxyz", origins)

    var ranges = mapped.source_ranges(ByteRange(0, 4))
    assert_equal(len(ranges), 2)
    assert_true(ranges[0] == ByteRange(8, 9))
    assert_true(ranges[1] == ByteRange(0, 5))

    var matched_positions: List[Int] = [0, 1, 2, 3]
    var matched_sources = mapped.source_ranges_of_code_points(matched_positions)
    assert_equal(len(matched_sources), 2)
    assert_true(matched_sources[0] == ByteRange(8, 9))
    assert_true(matched_sources[1] == ByteRange(0, 5))


def test_mapped_text_repeated_and_contained_ranges_keep_component_order() raises:
    var origins: List[ByteRange] = [
        ByteRange(4, 6),
        ByteRange(0, 1),
        ByteRange(4, 5),
        ByteRange(4, 6),
    ]
    var mapped = MappedText("abcdef", "wxyz", origins)

    var ranges = mapped.source_ranges(ByteRange(0, 4))
    assert_equal(len(ranges), 2)
    assert_true(ranges[0] == ByteRange(4, 6))
    assert_true(ranges[1] == ByteRange(0, 1))

    var matched_positions: List[Int] = [0, 1, 2, 3]
    var matched_sources = mapped.source_ranges_of_code_points(matched_positions)
    assert_equal(len(matched_sources), 2)
    assert_true(matched_sources[0] == ByteRange(4, 6))
    assert_true(matched_sources[1] == ByteRange(0, 1))


def test_mapped_text_merges_touching_ranges_but_preserves_one_byte_gaps() raises:
    var origins: List[ByteRange] = [
        ByteRange(0, 1),
        ByteRange(2, 3),
        ByteRange(1, 2),
        ByteRange(4, 5),
    ]
    var mapped = MappedText("abcde", "wxyz", origins)

    var ranges = mapped.source_ranges(ByteRange(0, 4))
    assert_equal(len(ranges), 2)
    assert_true(ranges[0] == ByteRange(0, 3))
    assert_true(ranges[1] == ByteRange(4, 5))

    var matched_positions: List[Int] = [0, 1, 2, 3]
    var matched_sources = mapped.source_ranges_of_code_points(matched_positions)
    assert_equal(len(matched_sources), 2)
    assert_true(matched_sources[0] == ByteRange(0, 3))
    assert_true(matched_sources[1] == ByteRange(4, 5))


def test_mapped_text_empty_queries_return_empty_unions() raises:
    var origins: List[ByteRange] = [ByteRange(0, 1), ByteRange(1, 2)]
    var mapped = MappedText("ab", "xy", origins)
    assert_equal(len(mapped.source_ranges(ByteRange(1, 1))), 0)

    var positions = List[Int]()
    assert_equal(len(mapped.source_ranges_of_code_points(positions)), 0)


def test_large_sorted_union_matches_small_encounter_order_path() raises:
    var pattern: List[ByteRange] = [
        ByteRange(8, 9),
        ByteRange(4, 5),
        ByteRange(0, 1),
        ByteRange(1, 4),
        ByteRange(12, 13),
        ByteRange(10, 12),
    ]
    var small = MappedText("abcdefghijklm", "uvwxyz", pattern)
    var small_ranges = small.source_ranges(ByteRange(0, 6))
    assert_equal(len(small_ranges), 3)
    assert_true(small_ranges[0] == ByteRange(8, 9))
    assert_true(small_ranges[1] == ByteRange(0, 5))
    assert_true(small_ranges[2] == ByteRange(10, 13))

    var transformed = String()
    var expanded = List[ByteRange](capacity=72)
    var positions = List[Int](capacity=72)
    for pattern_index in range(len(pattern)):
        for _ in range(12):
            transformed += "x"
            expanded.append(pattern[pattern_index])
            positions.append(len(positions))
    var large = MappedText("abcdefghijklm", transformed, expanded)

    var range_union = large.source_ranges(ByteRange(0, 72))
    assert_equal(len(range_union), len(small_ranges))
    var position_union = large.source_ranges_of_code_points(positions)
    assert_equal(len(position_union), len(small_ranges))
    for index in range(len(small_ranges)):
        assert_true(range_union[index] == small_ranges[index])
        assert_true(position_union[index] == small_ranges[index])


def test_sorted_union_threshold_handles_nonzero_ranges_and_sparse_positions() raises:
    var pattern: List[ByteRange] = [
        ByteRange(8, 9),
        ByteRange(4, 5),
        ByteRange(0, 1),
        ByteRange(1, 4),
    ]

    # A nonzero transformed range exercises exactly 63 (small scan) and 64
    # (sorted sweep) selected mappings with the same final exact union.
    var ranged_text = String("p")
    var ranged_origins = List[ByteRange](capacity=65)
    ranged_origins.append(ByteRange(12, 13))
    for index in range(64):
        ranged_text += "x"
        ranged_origins.append(pattern[index % len(pattern)])
    var ranged = MappedText("abcdefghijklm", ranged_text, ranged_origins)
    var below = ranged.source_ranges(ByteRange(1, 64))
    var at_threshold = ranged.source_ranges(ByteRange(1, 65))
    assert_equal(len(below), 2)
    assert_equal(len(at_threshold), 2)
    assert_true(below[0] == ByteRange(8, 9))
    assert_true(below[1] == ByteRange(0, 5))
    assert_true(at_threshold[0] == below[0])
    assert_true(at_threshold[1] == below[1])

    # Sparse matcher positions select the same pattern while skipping unrelated
    # transformed scalars; total selected count, not position density, dispatches.
    var sparse_text = String()
    var sparse_origins = List[ByteRange](capacity=128)
    var sparse_positions = List[Int](capacity=64)
    for index in range(64):
        sparse_text += "xy"
        sparse_origins.append(pattern[index % len(pattern)])
        sparse_origins.append(ByteRange(12, 13))
        sparse_positions.append(2 * index)
    var sparse = MappedText("abcdefghijklm", sparse_text, sparse_origins)
    var sparse_threshold = sparse.source_ranges_of_code_points(sparse_positions)
    assert_equal(len(sparse_threshold), 2)
    assert_true(sparse_threshold[0] == ByteRange(8, 9))
    assert_true(sparse_threshold[1] == ByteRange(0, 5))

    _ = sparse_positions.pop()
    var sparse_below = sparse.source_ranges_of_code_points(sparse_positions)
    assert_equal(len(sparse_below), len(sparse_threshold))
    for index in range(len(sparse_below)):
        assert_true(sparse_below[index] == sparse_threshold[index])

    # Every component remains observable after sorting; output must retain the
    # alternating encounter permutation rather than source-offset order.
    var disjoint_source = String()
    var disjoint_text = String()
    var disjoint_origins = List[ByteRange](capacity=64)
    var disjoint_positions = List[Int](capacity=64)
    for _ in range(64):
        disjoint_source += "a_"
        disjoint_text += "x"
    for index in range(64):
        var source_slot = index // 2
        if index % 2 == 0:
            source_slot = 63 - source_slot
        disjoint_origins.append(ByteRange(2 * source_slot, 2 * source_slot + 1))
        disjoint_positions.append(index)
    var disjoint = MappedText(disjoint_source, disjoint_text, disjoint_origins)
    var disjoint_range_union = disjoint.source_ranges(ByteRange(0, 64))
    var disjoint_position_union = disjoint.source_ranges_of_code_points(
        disjoint_positions
    )
    assert_equal(len(disjoint_range_union), 64)
    assert_equal(len(disjoint_position_union), 64)
    for index in range(64):
        assert_true(disjoint_range_union[index] == disjoint_origins[index])
        assert_true(disjoint_position_union[index] == disjoint_origins[index])


def test_mapped_text_maps_combining_and_emoji_clusters_as_exact_source_ranges() raises:
    # `e + combining acute` occupies 0..3; thumbs-up plus skin tone occupies
    # 3..11. A transform may contract each whole grapheme to one output scalar.
    var origins: List[ByteRange] = [ByteRange(0, 3), ByteRange(3, 11)]
    var mapped = MappedText("é👍🏽", "e👍", origins)
    var ranges = mapped.source_ranges(ByteRange(1, 5))
    assert_equal(len(ranges), 1)
    assert_true(ranges[0] == ByteRange(3, 11))


def test_mapped_text_validates_mapping_shape_and_utf8_boundaries() raises:
    var too_short: List[ByteRange] = [ByteRange(0, 3)]
    with assert_raises(
        contains="mapping count 1 must equal transformed code-point count 2"
    ):
        _ = MappedText("北京", "ab", too_short)

    var split_source: List[ByteRange] = [ByteRange(1, 3)]
    with assert_raises(contains="byte offset 1 splits U+5317"):
        _ = MappedText("北", "a", split_source)

    var empty_source: List[ByteRange] = [ByteRange(0, 0)]
    with assert_raises(contains="source range at mapping 0 must be nonempty"):
        _ = MappedText("a", "a", empty_source)

    var past_source: List[ByteRange] = [ByteRange(0, 2)]
    with assert_raises(contains="byte range end 2 is outside text byte length 1"):
        _ = MappedText("a", "a", past_source)

    var valid: List[ByteRange] = [ByteRange(0, 3), ByteRange(0, 3)]
    var mapped = MappedText("北", "αβ", valid)
    with assert_raises(contains="byte offset 1 splits U+03B1"):
        _ = mapped.source_ranges(ByteRange(1, 2))
    with assert_raises(contains="byte offset 5 is outside text byte length 4"):
        _ = mapped.source_ranges(ByteRange(4, 5))


def test_empty_mapped_text_is_valid() raises:
    var origins = List[ByteRange]()
    var mapped = MappedText("", "", origins)
    assert_equal(mapped.code_point_count(), 0)
    assert_equal(len(mapped.source_ranges(ByteRange(0, 0))), 0)


def test_mapped_text_validate_rejects_mutated_storage() raises:
    var origins: List[ByteRange] = [ByteRange(0, 1)]
    var mapped = MappedText("a", "x", origins)
    mapped._source_ranges[0] = ByteRange(0, 0)
    with assert_raises(contains="source range at mapping 0 must be nonempty"):
        mapped.validate()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
