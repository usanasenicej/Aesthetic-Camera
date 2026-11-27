from __future__ import annotations


def clamp_channel(value: float) -> float:
    return max(0.0, min(255.0, value))


def mix_rgb(
    base: tuple[float, float, float],
    light: tuple[float, float, float],
    amount: float,
) -> tuple[float, float, float]:
    amount = max(0.0, min(1.0, amount))
    return (
        base[0] + (light[0] - base[0]) * amount,
        base[1] + (light[1] - base[1]) * amount,
        base[2] + (light[2] - base[2]) * amount,
    )
