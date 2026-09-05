"""Run the official Unicode 17.0.0 corpus through public grapheme operations."""

from moji import (
    ByteOffset,
    GraphemeBoundaryIndex,
    GraphemeIndex,
    byte_range_of_grapheme,
    count_graphemes,
    grapheme_index,
    grapheme_spans,
    slice_graphemes,
)
from std.collections import List
from std.testing import assert_equal, assert_raises


struct _Exception(Copyable):
    var line: Int
    var boundaries: List[Int]
    var seen: Bool

    def __init__(out self, line: Int, var boundaries: List[Int]):
        self.line = line
        self.boundaries = boundaries^
        self.seen = False


def _exceptions() raises -> List[_Exception]:
    var data: String
    with open("tests/fixtures/grapheme-exceptions-mojo-1.0.0.txt", "r") as fixture:
        data = fixture.read()
    var exceptions = List[_Exception]()
    for line in data.split("\n"):
        if line.startswith("#") or line.byte_length() == 0:
            continue
        var fields = line.split(";")
        assert_equal(len(fields), 3)
        var boundaries = List[Int]()
        for value in fields[1].split(","):
            boundaries.append(atol(value))
        exceptions.append(_Exception(atol(fields[0]), boundaries^))
    assert_equal(len(exceptions), 9)
    return exceptions^


def _check_case(
    text: StringSlice,
    var boundaries: List[Int],
    line_number: Int,
    mut exceptions: List[_Exception],
) raises:
    var actual = List[Int](length=1, fill=0)
    for span in grapheme_spans(text):
        actual.append(span.byte_range().end())
    var exception_index = -1
    for position in range(len(exceptions)):
        if exceptions[position].line == line_number:
            exception_index = position
            exceptions[position].seen = True
    if exception_index >= 0:
        if actual == boundaries:
            raise Error(
                String(
                    "Unicode corpus line ",
                    line_number,
                    ": stale compiler exception; remove it after reviewing the upgrade",
                )
            )
        boundaries = exceptions[exception_index].boundaries.copy()
    if actual != boundaries:
        raise Error(
            String(
                "Unicode corpus line ",
                line_number,
                ": expected byte boundaries ",
                boundaries,
                "; got ",
                actual,
            )
        )
    var count = len(boundaries) - 1
    var index = GraphemeBoundaryIndex(String(text))
    index.validate()
    assert_equal(count_graphemes(text), count)
    assert_equal(index.grapheme_count(), count)
    var cluster_index = 0
    for span in grapheme_spans(text):
        assert_equal(span.byte_range().start(), boundaries[cluster_index])
        assert_equal(span.byte_range().end(), boundaries[cluster_index + 1])
        var scalar_range = byte_range_of_grapheme(text, GraphemeIndex(cluster_index))
        assert_equal(scalar_range.start(), boundaries[cluster_index])
        assert_equal(scalar_range.end(), boundaries[cluster_index + 1])
        assert_equal(
            String(span.text()),
            String(
                index.slice(
                    GraphemeIndex(cluster_index), GraphemeIndex(cluster_index + 1)
                )
            ),
        )
        cluster_index += 1
    for position in range(count + 1):
        assert_equal(
            grapheme_index(text, ByteOffset(boundaries[position])).value(), position
        )
        assert_equal(
            index.byte_offset(GraphemeIndex(position)).value(), boundaries[position]
        )
        assert_equal(
            index.grapheme_index(ByteOffset(boundaries[position])).value(), position
        )
        for end in range(position, count + 1):
            var expected = String(text[byte = boundaries[position] : boundaries[end]])
            assert_equal(
                slice_graphemes(text, GraphemeIndex(position), GraphemeIndex(end)),
                expected,
            )
            assert_equal(
                String(index.slice(GraphemeIndex(position), GraphemeIndex(end))),
                expected,
            )
    cluster_index = 1
    for offset in range(1, text.byte_length()):
        if offset == boundaries[cluster_index]:
            cluster_index += 1
        else:
            with assert_raises(contains="inside a grapheme cluster"):
                _ = grapheme_index(text, ByteOffset(offset))
            with assert_raises(contains="inside a grapheme cluster"):
                _ = index.grapheme_index(ByteOffset(offset))


def main() raises:
    var data: String
    with open("tests/fixtures/unicode-17.0.0/GraphemeBreakTest.txt", "r") as fixture:
        data = fixture.read()
    var line_number = 0
    var cases = 0
    var exceptions = _exceptions()
    for line in data.split("\n"):
        line_number += 1
        if line.strip().startswith("#") or line.strip().byte_length() == 0:
            continue
        var fields = line.split("#", 1)[0].strip()
        if fields.byte_length() == 0:
            continue
        var text = String()
        var boundaries = List[Int]()
        for token in fields.split():
            if token == "÷":
                boundaries.append(text.byte_length())
            elif not token == "×":
                text += chr(atol(token, 16))
        _check_case(text, boundaries^, line_number, exceptions)
        cases += 1
    assert_equal(cases, 766)
    _check_case("", List[Int](length=1, fill=0), 0, exceptions)
    for exception in exceptions:
        if not exception.seen:
            raise Error(String("Unused grapheme exception for line ", exception.line))
    print(
        "Unicode 17.0.0 grapheme corpus: ",
        cases,
        " cases + empty text; 757 Unicode matches, 9 exact compiler exceptions",
        sep="",
    )
