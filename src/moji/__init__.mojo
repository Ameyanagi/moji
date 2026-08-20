"""Unicode application text primitives with explicit byte-index contracts."""

from .byte_range import (
    ByteRange,
    is_utf8_boundary,
    slice_text,
    validate_text_range,
)
from .position import ByteOffset, CodePointIndex, DisplayColumn, GraphemeIndex
