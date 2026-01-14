#!/usr/bin/env python3
"""Berlin Transport Map — App Store assets validator

Validates *source-of-truth* assets committed to the repo:
- Fastlane metadata: required files present for each locale
- Apple keyword field length (<= 100 chars) + obvious hygiene
- Screenshots: expected filenames present per locale
- App icon: delegates to ./generate_icon.py (AppIcon.icon workflow)

This is intentionally lightweight and dependency-free, so it can run in CI.

Usage:
  python3 scripts/validate_app_store_assets.py
"""

from __future__ import annotations

import os
import subprocess
import sys
import struct
from dataclasses import dataclass


REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


@dataclass(frozen=True)
class CheckResult:
    ok: bool
    message: str


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_png_size(path: str) -> tuple[int, int]:
    """Return (width, height) from a PNG without external dependencies."""
    with open(path, "rb") as f:
        sig = f.read(8)
        if sig != PNG_SIGNATURE:
            raise ValueError("not a PNG")

        length_bytes = f.read(4)
        chunk_type = f.read(4)
        if len(length_bytes) != 4 or len(chunk_type) != 4:
            raise ValueError("truncated")

        length = struct.unpack(">I", length_bytes)[0]
        if chunk_type != b"IHDR":
            raise ValueError("unexpected first chunk")

        ihdr = f.read(length)
        if len(ihdr) < 8:
            raise ValueError("truncated IHDR")

        width, height = struct.unpack(">II", ihdr[:8])
        return int(width), int(height)


def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip("\n")


def check_exists(path: str, kind: str = "file") -> CheckResult:
    exists = os.path.isfile(path) if kind == "file" else os.path.isdir(path)
    return CheckResult(ok=exists, message=("✓" if exists else "✗") + f" {kind}: {os.path.relpath(path, REPO_ROOT)}")


def run_icon_validator() -> CheckResult:
    script = os.path.join(REPO_ROOT, "generate_icon.py")
    if not os.path.isfile(script):
        return CheckResult(False, "✗ Missing generate_icon.py (icon validator)")

    try:
        proc = subprocess.run([sys.executable, script], cwd=REPO_ROOT, text=True, capture_output=True)
    except Exception as e:
        return CheckResult(False, f"✗ Failed to run icon validator: {e}")

    out = (proc.stdout or "").strip()
    err = (proc.stderr or "").strip()

    if proc.returncode == 0:
        return CheckResult(True, "✓ App icon validator: OK")

    detail = "\n".join([s for s in [out, err] if s])
    return CheckResult(False, "✗ App icon validator failed\n" + (detail[:4000] if detail else ""))


def check_keywords(path: str) -> CheckResult:
    kw = read_text(path).replace("\n", "").strip()

    # Apple keyword field: 100 characters max.
    length = len(kw)
    ok = length <= 100

    trailing_comma = kw.endswith(",")
    double_commas = ",," in kw

    if trailing_comma or double_commas:
        ok = False

    msg = f"{'✓' if ok else '✗'} keywords ({length}/100): {os.path.relpath(path, REPO_ROOT)}"
    if not ok:
        msg += f"\n  value: {kw}"
        if length > 100:
            msg += "\n  reason: > 100 characters"
        if trailing_comma:
            msg += "\n  reason: trailing comma"
        if double_commas:
            msg += "\n  reason: double commas"
    return CheckResult(ok, msg)


def check_metadata_locale(locale_dir: str) -> list[CheckResult]:
    required = [
        "name.txt",
        "subtitle.txt",
        "description.txt",
        "keywords.txt",
        "marketing_url.txt",
        "privacy_url.txt",
        "support_url.txt",
        "promotional_text.txt",
        "release_notes.txt",
    ]

    results: list[CheckResult] = []
    results.append(check_exists(locale_dir, kind="dir"))

    for filename in required:
        results.append(check_exists(os.path.join(locale_dir, filename), kind="file"))

    kw_path = os.path.join(locale_dir, "keywords.txt")
    if os.path.isfile(kw_path):
        results.append(check_keywords(kw_path))

    return results


def check_screenshots(locale: str) -> list[CheckResult]:
    # Keep this list strict: failing the check tells us what's missing.
    expected = [
        "iPhone67_01_map.png",
        "iPhone67_02_live.png",
        "iPhone67_03_detail.png",
        "iPad_Pro_13_01.png",
        "iPad_Pro_13_02.png",
        "iPad_Pro_13_03.png",
    ]

    # Common acceptable resolutions (portrait) for these device classes.
    # Apple accepts multiple device sizes; we allow the most common ones so the
    # validator is helpful rather than brittle.
    allowed_sizes = {
        "iPhone67": {
            (1290, 2796),  # iPhone 15 Pro Max / 6.7"
            (1284, 2778),  # iPhone 12/13/14 Pro Max class
            (1242, 2688),  # older 6.5" class (still accepted for some apps)
            (1320, 2868),  # iPhone 16 Pro Max / 6.9" (sometimes used)
        },
        "iPad_Pro_13": {
            (2064, 2752),  # iPad Pro 13" (M4)
            (2048, 2732),  # iPad Pro 12.9" (legacy)
        },
    }

    dir_path = os.path.join(REPO_ROOT, "fastlane", "screenshots", locale)
    results: list[CheckResult] = [check_exists(dir_path, kind="dir")]

    # Collect presence + sizes for scoring.
    score = 10
    present = 0
    size_warnings: list[str] = []

    for filename in expected:
        path = os.path.join(dir_path, filename)
        exists_res = check_exists(path, kind="file")
        results.append(exists_res)
        if not exists_res.ok:
            score -= 2
            continue

        present += 1
        try:
            w, h = read_png_size(path)
        except Exception as e:
            score -= 2
            results.append(CheckResult(False, f"✗ screenshot PNG parse failed: {os.path.relpath(path, REPO_ROOT)} ({e})"))
            continue

        key = "iPhone67" if filename.startswith("iPhone67_") else "iPad_Pro_13"
        if (w, h) not in allowed_sizes[key]:
            # Don't fail hard by default, but surface it and nudge the score.
            size_warnings.append(f"{filename} is {w}×{h} (expected one of {sorted(allowed_sizes[key])})")
            score -= 1

    # Summary line (always included).
    score = max(0, min(10, score))
    results.append(CheckResult(True, f"✓ screenshots score: {score}/10 ({present}/{len(expected)} files present)"))

    if size_warnings:
        for w in size_warnings:
            results.append(CheckResult(True, f"⚠️  screenshot size: {w}"))

    return results


def main() -> int:
    failures: list[str] = []

    print("Berlin Transport Map — App Store assets validation\n")

    # 1) Icon
    icon_res = run_icon_validator()
    print(icon_res.message)
    if not icon_res.ok:
        failures.append("icon")
    print()

    # 2) Metadata
    metadata_root = os.path.join(REPO_ROOT, "fastlane", "metadata")
    print(check_exists(metadata_root, kind="dir").message)

    for locale in ["en-US", "de-DE"]:
        locale_dir = os.path.join(metadata_root, locale)
        print(f"\nMetadata: {locale}")
        for r in check_metadata_locale(locale_dir):
            print(r.message)
            if not r.ok:
                failures.append(f"metadata:{locale}")

    # 3) Screenshots
    for locale in ["en-US", "de-DE"]:
        print(f"\nScreenshots: {locale}")
        for r in check_screenshots(locale):
            print(r.message)
            if not r.ok:
                failures.append(f"screenshots:{locale}")

    if failures:
        print("\n⚠️  Validation failed.")
        print("Fix the missing/invalid items above before shipping App Store updates.")
        return 1

    print("\n✓ All App Store assets look consistent.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
