# Changelog

All notable changes to Berlin Transport Map are documented here.

## [1.5] - 2026-04-09

### Added
- First-launch welcome overlay — a 3-screen onboarding flow (Welcome → Features → Location Priming) shown once on first install. Explains live transit tracking, highlights key interactions, and requests location permission with context about why it's useful.
- Location auto-center — map now centers on your position automatically when location is first granted, so you see your neighborhood immediately instead of a city-wide view.
- Onboarding analytics — tracks which welcome screen users reach and whether location was requested, so drop-off can be measured over time.

### Changed
- tvOS compatibility — all iOS-only APIs now gated with `#if !os(tvOS)`: navigation bar title display modes, review request prompt, user location button, share sheet, and toolbar positions across 5 views (Settings, About, Help, TransportMap, Favorites). The app now builds and runs cleanly on Apple TV.
- Route favorites now show a clear "Route Replay Unavailable" alert instead of silently doing nothing when tapped. Stop favorites continue to work normally.
- VoiceOver hint for route favorites updated to reflect the new behavior ("Route replay not yet available").

### Fixed
- Fixed silent failure when tapping a saved route favorite — the broken dummy-route path that called `focusCamera(on: [])` with an empty coordinate list has been removed.
- Fixed dead `delay` parameter in feature row animations — the parameter was accepted but never applied, causing all feature rows to animate simultaneously. Parameter removed for clarity.
