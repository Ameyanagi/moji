"""Nominal nonnegative coordinate values for text APIs."""


def _validate_nonnegative(value: Int, unit: String) raises:
    if value < 0:
        raise Error(unit + " must be nonnegative")


struct ByteOffset(Copyable, Equatable):
    """A nonnegative UTF-8 byte offset.

    This value names a byte coordinate but is not tied to a particular string.
    Text-dependent boundary and bounds validation belongs to conversion APIs.
    Reads trust the constructor-established invariant. Direct mutation of
    underscore-prefixed storage is out of contract; call `validate()` explicitly
    after unusual low-level mutation when a checkpoint is needed.
    """

    var _value: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "byte offset")
        self._value = value

    def validate(self) raises:
        """Validate the stored byte offset explicitly."""
        _validate_nonnegative(self._value, "byte offset")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __lt__(self, other: Self) -> Bool:
        return self._value < other._value

    def __le__(self, other: Self) -> Bool:
        return self._value <= other._value

    def __gt__(self, other: Self) -> Bool:
        return self._value > other._value

    def __ge__(self, other: Self) -> Bool:
        return self._value >= other._value


struct CodePointIndex(Copyable, Equatable):
    """A nonnegative index in a sequence of Unicode code points.

    This value does not retain or borrow the text whose position it describes.
    Reads trust the constructor-established invariant. Direct mutation of
    underscore-prefixed storage is out of contract; call `validate()` explicitly
    after unusual low-level mutation when a checkpoint is needed.
    """

    var _value: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "code-point index")
        self._value = value

    def validate(self) raises:
        """Validate the stored code-point index explicitly."""
        _validate_nonnegative(self._value, "code-point index")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __lt__(self, other: Self) -> Bool:
        return self._value < other._value

    def __le__(self, other: Self) -> Bool:
        return self._value <= other._value

    def __gt__(self, other: Self) -> Bool:
        return self._value > other._value

    def __ge__(self, other: Self) -> Bool:
        return self._value >= other._value


struct GraphemeIndex(Copyable, Equatable):
    """A nonnegative index in an extended-grapheme-cluster sequence.

    This value does not retain or borrow the text whose position it describes.
    Reads trust the constructor-established invariant. Direct mutation of
    underscore-prefixed storage is out of contract; call `validate()` explicitly
    after unusual low-level mutation when a checkpoint is needed.
    """

    var _value: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "grapheme index")
        self._value = value

    def validate(self) raises:
        """Validate the stored grapheme index explicitly."""
        _validate_nonnegative(self._value, "grapheme index")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __lt__(self, other: Self) -> Bool:
        return self._value < other._value

    def __le__(self, other: Self) -> Bool:
        return self._value <= other._value

    def __gt__(self, other: Self) -> Bool:
        return self._value > other._value

    def __ge__(self, other: Self) -> Bool:
        return self._value >= other._value


struct DisplayColumn(Copyable, Equatable):
    """A nonnegative terminal display-column coordinate.

    This value carries no width policy and does not retain or borrow text.
    Text-dependent conversion is introduced only after width semantics exist.
    Reads trust the constructor-established invariant. Direct mutation of
    underscore-prefixed storage is out of contract; call `validate()` explicitly
    after unusual low-level mutation when a checkpoint is needed.
    """

    var _value: Int

    def __init__(out self, value: Int) raises:
        _validate_nonnegative(value, "display column")
        self._value = value

    def validate(self) raises:
        """Validate the stored display column explicitly."""
        _validate_nonnegative(self._value, "display column")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __lt__(self, other: Self) -> Bool:
        return self._value < other._value

    def __le__(self, other: Self) -> Bool:
        return self._value <= other._value

    def __gt__(self, other: Self) -> Bool:
        return self._value > other._value

    def __ge__(self, other: Self) -> Bool:
        return self._value >= other._value
