# Changelog

All notable changes to Berlin Transport Map are documented here.

## [1.7] - 2026-04-28

### Added
- Multi-city foundation — the app now supports 10 German cities (Berlin, Munich, Hamburg, Frankfurt, Cologne, Stuttgart, Düsseldorf, Dresden, Leipzig, Nürnberg) with a city picker in Settings. Berlin remains the default and the only fully-validated city; non-Berlin cities run in departures-only mode until their API endpoints are validated. Live vehicle radar and the Berlin events card stay Berlin-only via per-city capability flags.
- City picker UI — pick a city from the toolbar or Settings. Switching cities cancels in-flight fetches, swaps the API endpoint, refreshes the widget, clears predictive cache, and updates the offline stops database.
- Multi-city favorites — every favorite carries the city it was saved in, so the same stop ID can exist as separate favorites in different cities. Cross-city dedup is per `(stopId, cityId)`.
- Multi-city widget — the home-screen widget now resolves the API endpoint per saved stop, so a Munich favorite hits the DB endpoint and a Berlin favorite hits VBB. Widget deep links carry the city ID so opening from the widget switches to the right city before showing departures.
- Notifications carry city — commute alerts now save with their city. A Munich alert opens the Munich version of the stop, not the Berlin one.

### Changed
- `OfflineStopsDatabase` is now a per-city actor. Cache files are namespaced (`{cityId}_all_stops_cached.json`), the download grid comes from each city's bounding box, and search results no longer leak Berlin stops into Munich queries.
- App home-screen label changed from "Berlin Transport" to "Transit Map" so non-Berlin users don't see a Berlin-branded icon. App Store listing name unchanged.
- Map tile preloader now warms the active city's tiles instead of hard-coding Berlin coordinates.

### Fixed
- City switch race — switching cities while a vehicle or stops fetch was in flight could surface old-city data on the new map. Views now cancel in-flight fetches before clearing local state.
- Deep-link race — opening a widget link to a different city than the user is currently in opened the departures sheet against the old API. The sheet now waits for the city switch to complete before fetching.
- Offline download race — switching cities mid-download no longer poisons the new city's cache with the old city's stops. The download aborts and discards stale results when the active city changes.
- Search short-circuit — the offline stops search now confirms it represents the active city before short-circuiting, preventing Berlin matches from surfacing in a Munich query.

### Removed
- `ios/TransportWidget.swift` — legacy widget never wired into the Xcode project. Superseded by `DepartureWidget/`.

### Internal
- 22 new unit tests covering `CityConfig`, `CityManager`, `ServiceContainer.updateCity` propagation + race regression, `Favorite` cityId migration + per-city dedup, and `OfflineStopsDatabase` per-city behavior. All 62 tests pass.
- Explicit `DepartureWidget/Info.plist` replaces the auto-generated plist that was rejected by the iOS 26.4 simulator install path with `extensionDictionary must be set` — tests now actually run.

## [1.6] - 2026-04-13

### Added
- Personalised onboarding — a 9-screen first-launch flow that learns your transit goal, identifies your pain points, asks for location permission with context, shows a live departure demo with stops you pick, and closes with the tip jar. Shown once on fresh install (and once more if you were an existing user, so you can try the stop picker).
- Stop picker demo in onboarding — pick up to 3 favourite stops during setup. They land directly in Favourites, ready when you open the map.
- Tip jar — support the app with a one-time tip from inside the onboarding flow or the Settings screen.

### Changed
- Onboarding is now 9 screens instead of 12. Removed the Tinder-card swipe mechanic (swipe direction was never used for personalisation) and the transit type picker (selections were collected but never applied to the map). Both screens created friction without delivering on their promise.
- Existing users will see the new onboarding once on next launch so they can try the stop picker and tip jar they missed.

### Fixed
- Fixed onboarding getting permanently stuck on the "Loading your Berlin" processing screen. The screen never auto-advanced because the SwiftUI `.task` was keyed to a value that never changed at the right moment. Keying it to the current step number fixes the re-fire timing.
- Fixed the departure preview screen claiming to show live data ("Here's what's coming right now.") when it was showing static sample departures. Label now reads "Example departures — your live data loads in the app."
- Fixed tip purchase buttons remaining tappable during the async purchase request, making double-taps possible. Buttons are now disabled while the purchase is in progress.

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
