"""Builds Almanac's Android launcher icons from the approved artwork.

Development tool only: run it by hand when the approved artwork changes.
Nothing here is part of the app, and the app does not depend on Pillow.

    pip install pillow
    python3 tool/app_icon/generate_android_launcher_icons.py

The approved artwork (`almanac_icon_source.png`, 1254 x 1254, the
moon-and-sun on cream) is used as-is: it is only resized, never redrawn,
recoloured or cropped.

* Legacy icons (`mipmap-*/ic_launcher.png`, 48dp) are the whole square
  artwork, resized.
* Adaptive icons (API 26+, `mipmap-anydpi-v26/ic_launcher.xml`) are a
  solid cream background layer (the artwork's own background colour) and
  a foreground layer holding the whole square artwork, centred on a
  transparent 108dp canvas. It is scaled so the farthest-reaching piece
  of the artwork (a star tip) sits on the edge of the 66dp safe-zone
  circle, so no launcher mask can clip any of it.
"""

import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).with_name("almanac_icon_source.png")
RES = ROOT / "android" / "app" / "src" / "main" / "res"

# The artwork's flat cream background, measured from its margins.
BACKGROUND = (250, 238, 212)

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

LEGACY_DP = 48
ADAPTIVE_DP = 108
SAFE_RADIUS_DP = 33  # the 66dp safe-zone circle


def art_radius(image: Image.Image) -> float:
    """How far, in source pixels, the artwork reaches from the centre."""
    width, height = image.size
    pixels = image.load()
    cx, cy = (width - 1) / 2, (height - 1) / 2
    furthest = 0.0
    for y in range(height):
        for x in range(width):
            pixel = pixels[x, y]
            if max(abs(pixel[i] - BACKGROUND[i]) for i in range(3)) > 18:
                furthest = max(furthest, math.hypot(x - cx, y - cy))
    return furthest


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    width, _ = source.size
    radius = art_radius(source)
    # The artwork's width in dp once its furthest point is on the safe
    # zone's edge.
    art_dp = width * SAFE_RADIUS_DP / radius
    print(f"artwork reaches {radius:.1f}px; drawn {art_dp:.1f}dp of 108dp")

    for name, scale in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)

        legacy = round(LEGACY_DP * scale)
        source.resize((legacy, legacy), Image.LANCZOS).save(
            folder / "ic_launcher.png", optimize=True
        )

        canvas_px = round(ADAPTIVE_DP * scale)
        art_px = math.floor(art_dp * scale)
        foreground = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))
        offset = (canvas_px - art_px) // 2
        foreground.paste(
            source.resize((art_px, art_px), Image.LANCZOS).convert("RGBA"),
            (offset, offset),
        )
        foreground.save(folder / "ic_launcher_foreground.png", optimize=True)
        print(f"{name}: legacy {legacy}px, adaptive {canvas_px}px "
              f"(art {art_px}px)")


if __name__ == "__main__":
    main()
