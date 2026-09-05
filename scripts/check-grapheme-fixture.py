#!/usr/bin/env python3
"""Check the vendored official fixture bytes without network access."""

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "tests/fixtures/unicode-17.0.0"
FILES = {
    "GraphemeBreakTest.txt": "e2d134d2c52919bace503ebb6a551c1855fe1a1faec18478c78fff254a1793ec",
    "LICENSE.txt": "e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96",
}

for filename, expected in FILES.items():
    actual = hashlib.sha256((ROOT / filename).read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f"{filename}: SHA-256 {actual}; expected {expected}")
print("Unicode 17.0.0 grapheme fixture and license checksums passed.")
