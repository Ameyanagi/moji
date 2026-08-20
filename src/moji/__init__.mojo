"""Unicode application text primitives with explicit byte-index contracts."""

from .byte_range import (
    ByteRange,
    is_utf8_boundary,
    slice_text,
    validate_text_range,
)
from .conversion import (
    byte_offset_of,
    code_point_index,
    count_code_points,
    floor_utf8_boundary,
)
from .position import ByteOffset, CodePointIndex, DisplayColumn, GraphemeIndex
