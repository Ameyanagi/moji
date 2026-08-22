"""Nominal nonnegative coordinate values for text APIs."""

from std.io import Writable, Writer


struct _Validated:
    def __init__(out self):
        pass


def _validate_nonnegative(value: Int, unit: String) raises:
    if value < 0:
        raise Error(String(unit, " must be nonnegative, got ", value))


struct ByteOffset(Copyable, Equatable, Writable):
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

    @staticmethod
    def _from_validated(value: Int) -> Self:
        """Construct a byte offset whose nonnegative value is already trusted."""
        return Self(value, _validated=_Validated())

    def __init__(out self, value: Int, *, _validated: _Validated):
        self._value = value

    def validate(self) raises:
        """Validate the stored byte offset explicitly."""
        _validate_nonnegative(self._value, "byte offset")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def write_to[W: Writer](self, mut writer: W):
        """Write the bare UTF-8 byte offset."""
        writer.write(self._value)

    def __add__(self, delta: Int) raises -> Self:
        """Advance this UTF-8 byte offset by `delta` bytes.

        Raises when the resulting byte offset would be negative.
        """
        var result = self._value + delta
        _validate_nonnegative(result, "byte offset arithmetic result")
        return Self._from_validated(result)

    def __sub__(self, delta: Int) raises -> Self:
        """Move this UTF-8 byte offset backward by `delta` bytes.

        Raises when the resulting byte offset would be negative.
        """
        var result = self._value - delta
        _validate_nonnegative(result, "byte offset arithmetic result")
        return Self._from_validated(result)

    def __sub__(self, other: Self) -> Int:
        """Return the signed UTF-8 byte difference from `other`."""
        return self._value - other._value

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


struct CodePointIndex(Copyable, Equatable, Writable):
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

    @staticmethod
    def _from_validated(value: Int) -> Self:
        """Construct a code-point index whose value is already trusted."""
        return Self(value, _validated=_Validated())

    def __init__(out self, value: Int, *, _validated: _Validated):
        self._value = value

    def validate(self) raises:
        """Validate the stored code-point index explicitly."""
        _validate_nonnegative(self._value, "code-point index")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def write_to[W: Writer](self, mut writer: W):
        """Write the bare code-point index."""
        writer.write(self._value)

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


struct GraphemeIndex(Copyable, Equatable, Writable):
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

    @staticmethod
    def _from_validated(value: Int) -> Self:
        """Construct a grapheme index whose value is already trusted."""
        return Self(value, _validated=_Validated())

    def __init__(out self, value: Int, *, _validated: _Validated):
        self._value = value

    def validate(self) raises:
        """Validate the stored grapheme index explicitly."""
        _validate_nonnegative(self._value, "grapheme index")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def write_to[W: Writer](self, mut writer: W):
        """Write the bare grapheme index."""
        writer.write(self._value)

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


struct DisplayColumn(Copyable, Equatable, Writable):
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

    @staticmethod
    def _from_validated(value: Int) -> Self:
        """Construct a display column whose value is already trusted."""
        return Self(value, _validated=_Validated())

    def __init__(out self, value: Int, *, _validated: _Validated):
        self._value = value

    def validate(self) raises:
        """Validate the stored display column explicitly."""
        _validate_nonnegative(self._value, "display column")

    def value(self) -> Int:
        """Return the nonnegative integer coordinate."""
        return self._value

    def write_to[W: Writer](self, mut writer: W):
        """Write the bare terminal display-column coordinate."""
        writer.write(self._value)

    def __add__(self, delta: Int) raises -> Self:
        """Advance this terminal display column by `delta` columns.

        Raises when the resulting display column would be negative.
        """
        var result = self._value + delta
        _validate_nonnegative(result, "display column arithmetic result")
        return Self._from_validated(result)

    def __sub__(self, delta: Int) raises -> Self:
        """Move this terminal display column backward by `delta` columns.

        Raises when the resulting display column would be negative.
        """
        var result = self._value - delta
        _validate_nonnegative(result, "display column arithmetic result")
        return Self._from_validated(result)

    def __sub__(self, other: Self) -> Int:
        """Return the signed terminal-column difference from `other`."""
        return self._value - other._value

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
