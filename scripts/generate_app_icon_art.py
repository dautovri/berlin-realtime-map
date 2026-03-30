#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ICON_PATH = ROOT / "BerlinTransportMap" / "AppIcon.icon" / "Assets" / "Image 3.png"
BACKUP_PATH = ROOT / "BerlinTransportMap" / "AppIcon.icon" / "Assets" / "Image 3.orig.png"
SIZE = 2048

YELLOW = (255, 204, 33, 255)
YELLOW_DARK = (255, 170, 25, 255)
NAVY = (17, 28, 48, 255)
CYAN = (61, 192, 255, 255)
GREEN = (57, 208, 116, 255)
RED = (255, 94, 94, 255)
WHITE = (247, 250, 255, 255)
SHADOW = (0, 0, 0, 110)


def draw_station(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, fill: tuple[int, int, int, int]) -> None:
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill, outline=WHITE, width=max(8, radius // 4))


def main() -> None:
    if ICON_PATH.exists() and not BACKUP_PATH.exists():
        BACKUP_PATH.write_bytes(ICON_PATH.read_bytes())

    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    # Soft shadow for the whole glyph.
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse((360, 250, 1688, 1578), fill=SHADOW)
    shadow_draw.polygon(((1024, 1710), (752, 1200), (1296, 1200)), fill=SHADOW)
    shadow = shadow.filter(ImageFilter.GaussianBlur(70))
    image.alpha_composite(shadow, (0, 28))

    # Bold map pin body.
    pin = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(pin)
    draw.ellipse((360, 220, 1688, 1548), fill=YELLOW, outline=(255, 238, 165, 255), width=18)
    draw.polygon(((1024, 1820), (760, 1180), (1288, 1180)), fill=YELLOW, outline=(255, 238, 165, 255), width=18)

    # Inner transit map lens.
    draw.ellipse((576, 432, 1472, 1328), fill=NAVY)
    draw.ellipse((608, 464, 1440, 1296), outline=(255, 238, 165, 120), width=16)

    line_w = 60
    draw.line((700, 960, 1360, 760), fill=CYAN, width=line_w)
    draw.line((744, 680, 1288, 1100), fill=GREEN, width=line_w)
    draw.line((720, 820, 1360, 820), fill=RED, width=line_w)

    station_r = 44
    for point, color in [
        ((700, 960), CYAN),
        ((1030, 860), CYAN),
        ((1360, 760), CYAN),
        ((744, 680), GREEN),
        ((1016, 892), GREEN),
        ((1288, 1100), GREEN),
        ((720, 820), RED),
        ((1040, 820), RED),
        ((1360, 820), RED),
    ]:
        draw_station(draw, point, station_r, color)

    # Live-location center pulse.
    draw.ellipse((944, 724, 1104, 884), fill=WHITE)
    draw.ellipse((974, 754, 1074, 854), fill=YELLOW_DARK)

    image.alpha_composite(pin)

    # Slight crispness boost.
    final = image.filter(ImageFilter.UnsharpMask(radius=2, percent=135, threshold=2))
    final.save(ICON_PATH)
    print(f"Generated {ICON_PATH}")
    if BACKUP_PATH.exists():
        print(f"Backup at {BACKUP_PATH}")


if __name__ == "__main__":
    main()
