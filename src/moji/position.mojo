"""Nominal nonnegative coordinate values for text APIs."""


def _validate_nonnegative(value: Int, unit: String) raises:
    if value < 0:
        raise Error(unit + " must be nonnegative")


def _semantic_value(value_hint: Int) -> Int:
    # Mojo 1.0 does not enforce private fields. Normalization ensures every
    # externally reachable storage value still denotes a valid coordinate.
    return max(value_hint, 0)


struct ByteOffset(Copyable, Equatable):
    """A nonnegative UTF-8 byte offset.

    This value names a byte coordinate but is not tied to a particular string.
    Text-dependent boundary and bounds validation belongs to conversion APIs.
    """

    var _value_hint: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "byte offset")
        self._value_hint = value

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return _semantic_value(self._value_hint)

    def __eq__(self, other: Self) -> Bool:
        return self.value() == other.value()

    def __lt__(self, other: Self) -> Bool:
        return self.value() < other.value()

    def __le__(self, other: Self) -> Bool:
        return self.value() <= other.value()

    def __gt__(self, other: Self) -> Bool:
        return self.value() > other.value()

    def __ge__(self, other: Self) -> Bool:
        return self.value() >= other.value()


struct CodePointIndex(Copyable, Equatable):
    """A nonnegative index in a sequence of Unicode code points.

    This value does not retain or borrow the text whose position it describes.
    """

    var _value_hint: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "code-point index")
        self._value_hint = value

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return _semantic_value(self._value_hint)

    def __eq__(self, other: Self) -> Bool:
        return self.value() == other.value()

    def __lt__(self, other: Self) -> Bool:
        return self.value() < other.value()

    def __le__(self, other: Self) -> Bool:
        return self.value() <= other.value()

    def __gt__(self, other: Self) -> Bool:
        return self.value() > other.value()

    def __ge__(self, other: Self) -> Bool:
        return self.value() >= other.value()


struct GraphemeIndex(Copyable, Equatable):
    """A nonnegative index in an extended-grapheme-cluster sequence.

    This value does not retain or borrow the text whose position it describes.
    """

    var _value_hint: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "grapheme index")
        self._value_hint = value

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return _semantic_value(self._value_hint)

    def __eq__(self, other: Self) -> Bool:
        return self.value() == other.value()

    def __lt__(self, other: Self) -> Bool:
        return self.value() < other.value()

    def __le__(self, other: Self) -> Bool:
        return self.value() <= other.value()

    def __gt__(self, other: Self) -> Bool:
        return self.value() > other.value()

    def __ge__(self, other: Self) -> Bool:
        return self.value() >= other.value()


struct DisplayColumn(Copyable, Equatable):
    """A nonnegative terminal display-column coordinate.

    This value carries no width policy and does not retain or borrow text.
    Text-dependent conversion is introduced only after width semantics exist.
    """

    var _value_hint: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "display column")
        self._value_hint = value

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return _semantic_value(self._value_hint)

    def __eq__(self, other: Self) -> Bool:
        return self.value() == other.value()

    def __lt__(self, other: Self) -> Bool:
        return self.value() < other.value()

    def __le__(self, other: Self) -> Bool:
        return self.value() <= other.value()

    def __gt__(self, other: Self) -> Bool:
        return self.value() > other.value()

    def __ge__(self, other: Self) -> Bool:
        return self.value() >= other.value()
