# Berlin Transport Map — App Store Marketing Checklist

This doc is the “source of truth” for polishing App Store materials (icon, screenshots, metadata).

## 1) App Icon (Apple’s new format)

This project uses Xcode’s newer icon workflow:

- `BerlinTransportMap/AppIcon.icon/`

Checklist:
- The base image layer is **at least 1024×1024** (today it’s validated).
- No tiny details that disappear at small sizes.
- High contrast on both light/dark home screens.
- Avoid text in the icon.

Validate locally:
- `python3 generate_icon.py`

## 2) Screenshots (conversion-first)

### Required coverage (baseline)

We currently ship (per locale):
- iPhone “6.7” class: 3 screenshots
- iPad Pro 13": 3 screenshots

### Recommended story arc (7–8 screenshots iPhone + 3–5 iPad)

1. **Hook:** “Vehicles move live on the map”
2. **Proof:** delays + departures at a stop
3. **Utility:** nearby stops (optional location)
4. **Control:** filter by U-Bahn / S-Bahn / Tram / Bus
5. **Confidence:** powered by real-time transit data
6. **Delight:** dark mode
7. **Privacy:** no account, no tracking

### Quality checklist

- First screenshot communicates the value in 1 second.
- Consistent status bar (time/battery), consistent locale.
- Readable at thumbnail size.
- If overlays are used: keep text minimal, big, and within safe areas.

Validate file presence + common resolutions:
- `python3 scripts/validate_app_store_assets.py`

## 3) Metadata

Source-of-truth lives under:
- `fastlane/metadata/en-US/`
- `fastlane/metadata/de-DE/`

### Support URL

Support URL should **not** equal Privacy Policy.

Current support page:
- `docs/support.md`

### Keywords

- Apple keyword field is **≤ 100 characters**.
- Prefer high-intent terms (departures/stops/delays, VBB) over generic ones.

## 4) App Preview video (optional, high impact)

Source video:
- `docs/screenshots/video.MP4`

If we add an App Preview, we should:
- Keep it short and readable (first 3 seconds should show the live map)
- Avoid tiny UI text
- Localize captions if used
