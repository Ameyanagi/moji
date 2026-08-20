"""Unicode-aware terminal display-width measurement."""

from ._unicode_width_data import is_ambiguous, is_emoji, is_wide, is_zero_width


# Unicode version pinned by the generated terminal-width tables. Widths are in
# terminal columns; reading this value is total and non-raising. The associated
# policy maps controls and default-ignorables to zero columns, supports narrow or
# wide ambiguous characters, and promotes emoji presentation sequences to two.
comptime UNICODE_DATA_VERSION = "17.0.0"


struct AmbiguousWidth(Copyable, Equatable, ImplicitlyCopyable):
    """Select the terminal-column width of East Asian Ambiguous scalars.

    Operations on this policy value are total and non-raising. Controls and
    default-ignorables remain zero columns, and emoji presentation sequences
    remain two columns, under either mode.
    """

    var _value: Int

    comptime NARROW = AmbiguousWidth(_value=0)
    comptime WIDE = AmbiguousWidth(_value=1)

    def __init__(out self, *, _value: Int):
        self._value = _value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value


def scalar_width(
    scalar: Codepoint, ambiguous: AmbiguousWidth = AmbiguousWidth.NARROW
) -> Int:
    """Return the terminal-column width of one Unicode scalar.

    This operation is total and non-raising. C0/C1 controls and DEL occupy zero
    columns, as do default-ignorables and zero-width combining scalars. Wide and
    emoji-presentation scalars occupy two columns. East Asian Ambiguous scalars
    occupy one column by default and two under ``AmbiguousWidth.WIDE``.
    """
    var value = Int(scalar.to_u32())
    if value <= 0 or value < 0x20 or (value >= 0x7F and value < 0xA0):
        return 0
    if is_zero_width(value):
        return 0
    if is_wide(value):
        return 2
    if ambiguous == AmbiguousWidth.WIDE and is_ambiguous(value):
        return 2
    return 1


def grapheme_width(
    grapheme: StringSlice, ambiguous: AmbiguousWidth = AmbiguousWidth.NARROW
) -> Int:
    """Return one grapheme cluster's terminal width in columns.

    This operation is total and non-raising. It takes the maximum scalar width,
    so controls, default-ignorables, and zero-width combining scalars add no
    columns. Fully-qualified emoji presentation and ZWJ clusters occupy two
    columns, including emoji plus VS16 promotion. Ambiguous width follows the
    selected policy and defaults to narrow.
    """
    if not grapheme:
        return 0

    var maximum_width = 0
    var has_emoji = False
    var has_emoji_selector = False
    for scalar in grapheme.codepoints():
        var value = Int(scalar.to_u32())
        if value == 0xFE0F:
            has_emoji_selector = True
        if is_emoji(value):
            has_emoji = True
        var width = scalar_width(scalar, ambiguous)
        if width > maximum_width:
            maximum_width = width

    if has_emoji and has_emoji_selector:
        return 2
    return maximum_width


def text_width(
    text: StringSlice, ambiguous: AmbiguousWidth = AmbiguousWidth.NARROW
) -> Int:
    """Return text's terminal display width in columns.

    This operation is total and non-raising and sums one width per extended
    grapheme cluster. Controls, default-ignorables, and combining scalars add no
    columns; fully-qualified emoji presentation and ZWJ sequences occupy two;
    and East Asian Ambiguous scalars are narrow by default or wide by opt-in.
    """
    var total = 0
    for grapheme in text.graphemes():
        total += grapheme_width(grapheme, ambiguous)
    return total
