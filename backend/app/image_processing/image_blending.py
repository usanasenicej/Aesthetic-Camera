from __future__ import annotations

import numpy as np


def screen_blend(base: np.ndarray, overlay: np.ndarray) -> np.ndarray:
    """Screen-blend two float RGB arrays in 0..255 space."""
    return 255.0 - ((255.0 - base) * (255.0 - overlay) / 255.0)
