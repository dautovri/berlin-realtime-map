#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS_ROOT = ROOT / "fastlane" / "screenshots"
TITLE = "No Account. No Tracking."
SUBTITLE = "Just Berlin transit data, fast and private."
POINTS = ["No sign-up", "No ads", "Location optional"]


def load_font(size: int, bold: bool = False):
    candidates = []
    if bold:
        candidates += [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/System/Library/Fonts/Supplemental/Helvetica.ttc",
        ]
    else:
        candidates += [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Supplemental/Helvetica.ttc",
        ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            try:
                return ImageFont.truetype(str(path), size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def add_badge(draw: ImageDraw.ImageDraw, box, text, font):
    draw.rounded_rectangle(box, radius=(box[3] - box[1]) // 2, fill=(255, 208, 43, 225), outline=(255, 241, 186, 235), width=3)
    bbox = draw.textbbox((0, 0), text, font=font)
    draw.text((box[0] + ((box[2] - box[0]) - (bbox[2] - bbox[0])) / 2, box[1] + ((box[3] - box[1]) - (bbox[3] - bbox[1])) / 2 - 1), text, font=font, fill=(56, 40, 4))


def render(base_path: Path, output_path: Path, is_ipad: bool) -> None:
    image = Image.open(base_path).convert("RGBA")
    width, height = image.size

    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    header_height = int(height * 0.19)
    for y in range(header_height):
        t = y / max(header_height - 1, 1)
        color = (
            int(196 - 18 * t),
            int(142 - 18 * t),
            int(18 + 10 * t),
            246,
        )
        draw.rectangle((0, y, width, y + 1), fill=color)

    title_font = load_font(int(height * (0.04 if is_ipad else 0.038)), bold=True)
    subtitle_font = load_font(int(height * (0.024 if is_ipad else 0.022)))
    badge_font = load_font(int(height * 0.017), bold=True)
    body_font = load_font(int(height * 0.023), bold=False)

    title_bbox = draw.textbbox((0, 0), TITLE, font=title_font)
    draw.text(((width - (title_bbox[2] - title_bbox[0])) / 2, height * 0.045), TITLE, font=title_font, fill=(249, 247, 240))
    subtitle_bbox = draw.textbbox((0, 0), SUBTITLE, font=subtitle_font)
    draw.text(((width - (subtitle_bbox[2] - subtitle_bbox[0])) / 2, height * 0.095), SUBTITLE, font=subtitle_font, fill=(255, 239, 201))

    card_w = int(width * (0.54 if is_ipad else 0.72))
    card_h = int(height * 0.18)
    card_x = int(width * 0.06)
    card_y = int(height * 0.72)

    card = Image.new("RGBA", image.size, (0, 0, 0, 0))
    card_draw = ImageDraw.Draw(card)
    card_draw.rounded_rectangle((card_x, card_y, card_x + card_w, card_y + card_h), radius=30, fill=(36, 30, 17, 214), outline=(255, 213, 58, 180), width=3)
    card = card.filter(ImageFilter.GaussianBlur(radius=0))
    overlay.alpha_composite(card)

    draw.text((card_x + 26, card_y + 20), "Berlin-only, privacy-first transit", font=body_font, fill=(249, 244, 228))
    draw.text((card_x + 26, card_y + 52), "Check departures and the live map without creating an account.", font=subtitle_font, fill=(234, 220, 179))

    badge_y = card_y + card_h - 48
    badge_w = int((card_w - 64) / 3)
    for idx, text in enumerate(POINTS):
        x0 = card_x + 22 + idx * (badge_w + 10)
        add_badge(draw, (x0, badge_y, x0 + badge_w, badge_y + 32), text, badge_font)

    final = Image.alpha_composite(image, overlay).convert("RGB")
    final.save(output_path, quality=95)
    print(f"Created {output_path}")


if __name__ == "__main__":
    for locale_dir in sorted(path for path in SCREENSHOTS_ROOT.iterdir() if path.is_dir()):
        render(locale_dir / "iPhone67_03_detail.png", locale_dir / "iPhone67_04_privacy.png", is_ipad=False)
        render(locale_dir / "iPad_Pro_13_03.png", locale_dir / "iPad_Pro_13_04_privacy.png", is_ipad=True)
