"""Unicode application text primitives with explicit byte-index contracts."""

from .byte_range import (
    ByteRange,
    is_utf8_boundary,
    slice_text,
    validate_text_range,
)
from .conversion import (
    byte_offset_of,
    byte_ranges_of_code_points,
    code_point_index,
    count_code_points,
    floor_utf8_boundary,
)
from .column import (
    ColumnSnap,
    byte_offset_at_column,
    display_column,
)
from .grapheme import (
    GraphemeSpan,
    GraphemeSpanIterator,
    byte_range_of_grapheme,
    count_graphemes,
    grapheme_index,
    grapheme_spans,
    slice_graphemes,
)
from .position import ByteOffset, CodePointIndex, DisplayColumn, GraphemeIndex
from .width import (
    UNICODE_DATA_VERSION,
    AmbiguousWidth,
    grapheme_width,
    scalar_width,
    text_width,
)
