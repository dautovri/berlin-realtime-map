#!/usr/bin/env python3
"""Berlin Transport Map — App Icon validator

This repository uses Apple's newer Xcode icon workflow: `BerlinTransportMap/AppIcon.icon/`.

Why this script exists:
- The previous version of this file attempted to generate an `Assets.xcassets/AppIcon.appiconset`.
- This project no longer uses that format, so the old script was misleading.

What this script does now:
- Validates that the `AppIcon.icon` asset exists.
- Checks that any referenced PNG layers exist and are at least 1024×1024.

It intentionally has **no third-party dependencies**.
"""

from __future__ import annotations

import json
import os
import struct
import sys
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class PNGSize:
    width: int
    height: int


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_png_size(file_path: str) -> PNGSize:
    with open(file_path, "rb") as f:
        sig = f.read(8)
        if sig != PNG_SIGNATURE:
            raise ValueError(f"Not a PNG file: {file_path}")

        # PNG structure: length (4) + chunk type (4) + data (len) + crc (4)
        length_bytes = f.read(4)
        chunk_type = f.read(4)
        if len(length_bytes) != 4 or len(chunk_type) != 4:
            raise ValueError(f"Truncated PNG header: {file_path}")

        length = struct.unpack(">I", length_bytes)[0]
        if chunk_type != b"IHDR":
            raise ValueError(f"Unexpected first chunk {chunk_type!r} in {file_path}")

        ihdr = f.read(length)
        if len(ihdr) != length:
            raise ValueError(f"Truncated IHDR chunk: {file_path}")

        width, height = struct.unpack(">II", ihdr[:8])
        return PNGSize(width=width, height=height)


def iter_icon_image_names(icon_json: dict) -> Iterable[str]:
    groups = icon_json.get("groups", [])
    for group in groups:
        for layer in group.get("layers", []):
            image_name = layer.get("image-name")
            if isinstance(image_name, str) and image_name:
                yield image_name


def main() -> int:
    repo_root = os.path.dirname(os.path.abspath(__file__))
    icon_dir = os.path.join(repo_root, "BerlinTransportMap", "AppIcon.icon")
    icon_json_path = os.path.join(icon_dir, "icon.json")
    icon_assets_dir = os.path.join(icon_dir, "Assets")

    if not os.path.isdir(icon_dir):
        print(f"✗ Missing icon directory: {icon_dir}")
        return 2
    if not os.path.isfile(icon_json_path):
        print(f"✗ Missing icon.json: {icon_json_path}")
        return 2
    if not os.path.isdir(icon_assets_dir):
        print(f"✗ Missing icon Assets directory: {icon_assets_dir}")
        return 2

    with open(icon_json_path, "r", encoding="utf-8") as f:
        icon_json = json.load(f)

    image_names = sorted(set(iter_icon_image_names(icon_json)))
    if not image_names:
        print("✗ No image layers referenced in icon.json")
        return 2

    ok = True
    print("AppIcon.icon validation")
    print(f"- icon.json: {os.path.relpath(icon_json_path, repo_root)}")
    print(f"- layers referenced: {len(image_names)}")

    for image_name in image_names:
        image_path = os.path.join(icon_assets_dir, image_name)
        if not os.path.isfile(image_path):
            print(f"✗ Missing layer image: {os.path.relpath(image_path, repo_root)}")
            ok = False
            continue

        try:
            size = read_png_size(image_path)
        except Exception as e:
            print(f"✗ Failed to read PNG size for {image_name}: {e}")
            ok = False
            continue

        min_side = min(size.width, size.height)
        status = "✓" if min_side >= 1024 else "!"
        print(f"{status} {image_name}: {size.width}×{size.height}")
        if min_side < 1024:
            ok = False

    if ok:
        print("\n✓ App icon looks good (AppIcon.icon workflow).")
        return 0

    print("\n⚠️  App icon validation failed.")
    print("Open the project in Xcode and edit the App Icon in the asset catalog (AppIcon.icon).")
    return 1


if __name__ == "__main__":
    sys.exit(main())
