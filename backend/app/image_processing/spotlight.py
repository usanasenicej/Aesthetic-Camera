from __future__ import annotations

import numpy as np
from PIL import Image

from .image_blending import screen_blend


def apply_spotlight(
    image: Image.Image,
    *,
    center_x: float,
    center_y: float,
    radius: float,
    intensity: float,
    softness: float,
    color: tuple[int, int, int],
) -> Image.Image:
    rgb = image.convert("RGB")
    pixels = np.asarray(rgb, dtype=np.float32)
    height, width = pixels.shape[:2]

    ys, xs = np.ogrid[:height, :width]
    distance = np.sqrt((xs - center_x * width) ** 2 + (ys - center_y * height) ** 2)
    max_span = max(width, height)
    outer = max(1.0, radius * max_span)
    inner = outer * (1.0 - min(max(softness, 0.02), 0.98))
    falloff = np.clip((outer - distance) / (outer - inner + 1e-6), 0.0, 1.0)
    falloff = falloff**1.35

    light = np.array(color, dtype=np.float32) * max(0.0, min(intensity, 1.5))
    overlay = falloff[..., None] * light
    blended = screen_blend(pixels, overlay)
    return Image.fromarray(np.clip(blended, 0, 255).astype(np.uint8), mode="RGB")
