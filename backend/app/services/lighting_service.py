from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO

from PIL import Image

from app.image_processing.spotlight import apply_spotlight

PRESETS = {
    "warm_portrait": {
        "name": "Warm Portrait",
        "center_x": 0.5,
        "center_y": 0.38,
        "radius": 0.55,
        "intensity": 0.58,
        "softness": 0.72,
        "color": [255, 224, 178],
    },
    "blue_studio": {
        "name": "Blue Studio",
        "center_x": 0.5,
        "center_y": 0.5,
        "radius": 0.7,
        "intensity": 0.46,
        "softness": 0.52,
        "color": [68, 138, 255],
    },
    "product_spotlight": {
        "name": "Product Spotlight",
        "center_x": 0.5,
        "center_y": 0.42,
        "radius": 0.32,
        "intensity": 0.78,
        "softness": 0.34,
        "color": [255, 255, 255],
    },
}


@dataclass
class LightingRequest:
    center_x: float
    center_y: float
    radius: float
    intensity: float
    softness: float
    color: tuple[int, int, int]


def process_lighting(image_bytes: bytes, request: LightingRequest) -> bytes:
    with Image.open(BytesIO(image_bytes)) as image:
        result = apply_spotlight(
            image,
            center_x=request.center_x,
            center_y=request.center_y,
            radius=request.radius,
            intensity=request.intensity,
            softness=request.softness,
            color=request.color,
        )
        output = BytesIO()
        result.save(output, format="JPEG", quality=92, optimize=True)
        return output.getvalue()
