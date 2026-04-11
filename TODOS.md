# TODOS

## WelcomeOverlay / Onboarding

### P1 — Active (v1.6)

- **WelcomeOverlay: ScrollView wrapper for Dynamic Type / landscape resilience**
  CRITICAL implementation notes from /autoplan Design Review (2026-04-11):
  1. Wrap only the inner headline+body VStack of each page. The CTA button MUST remain outside the scroll region (pinned at bottom of card), otherwise it scrolls out of reach.
  2. Replace `Spacer(minLength: 0)` inside page structs with explicit `.padding(.vertical, 24)` — Spacer collapses to zero inside ScrollView.
  3. Move entrance animation (`.offset(y: appeared ? 0 : 20)`) to the outer wrapper container, not the scroll content, to avoid scroll position conflicts.
  Affects: `WelcomePageContent`, `WelcomeFeaturesContent`, `WelcomeLocationContent` in WelcomeOverlayView.swift

- **WelcomeOverlay: Location button loading guard (isRequesting)**
  Add `@State var isRequesting = false` to WelcomeLocationContent. Disable "Allow Location" button while permission prompt is in flight. Reset on `authorizationStatus` change. Prevents double-tap firing two permission requests.

- **FeatureRow: @ScaledMetric for iconFrameSize**
  `WelcomeOverlayView.swift` — `FeatureRow` has a hardcoded `frame(width: 44, height: 44)` for the SF Symbol icon. At Accessibility XXL Dynamic Type sizes the frame clips the icon. Fix: `@ScaledMetric private var iconFrameSize: CGFloat = 44` and use `.frame(width: iconFrameSize, height: iconFrameSize)`.

### P2 — Followup

- **WelcomeOverlay: Version the `hasSeenWelcome` key**
  Current key is `"hasSeenWelcome"`. If onboarding content changes significantly, rename to `"hasSeenWelcomeV2"` so existing users see the new content.

- **WelcomeOverlay: Staggered feature row animations**
  Give each FeatureRow its own `appeared` state or use individual `.animation(.spring.delay(n))` modifiers for true stagger.

- **WelcomeOverlay: Already-granted location state**
  If user granted location before (reinstall), page 3 shows "Allow Location" which does nothing. Detect `.authorizedWhenInUse` / `.authorizedAlways` on page 3 and show "You're all set" + skip straight to dismiss.

- **WelcomeOverlay: Features heading scale**
  `WelcomeFeaturesContent` heading uses `.headline` (same weight as FeatureRow titles). Use `.title.bold()` for the section heading to create visual hierarchy.

- **TransitBadge: Fixed frame clips at AX type**
  `TransitBadge` has hardcoded `frame(width: 36, height: 36)`. Use `@ScaledMetric` or padding-based sizing to prevent clipping at Accessibility XXL.

- **WelcomeOverlay: Unit test harness**
  No unit tests exist for any onboarding flow. Add tests for: first-launch gate (`hasSeenWelcome`), page navigation, location permission guard.
  **Deferred from:** /autoplan (2026-04-11, P3 — separate sprint)

## TransportMap

### P1 — Active (v1.6)

- **Stop-tap async race fix**
  `TransportMapView.swift` ~line 519. In `loadDepartures(for stop:)`, add:
  `guard selectedStop?.id == stop.id else { isLoadingDepartures = false; return }`
  immediately before writing `restDepartures`. This discards stale responses when the user taps a second stop before the first response arrives.

- **vehicleFetchCount: cap to prevent AppStorage bloat**
  `TransportMapView.swift` line 651. Current: `vehicleFetchCount += 1`.
  Fix: `if vehicleFetchCount < 21 { vehicleFetchCount += 1 }`.
  ⚠️ Do NOT cap at 20 — that would cause `vehicleFetchCount == 20` to match on every subsequent fetch, spamming the review dialog. Cap at 21 so the `== 20` check fires once and is never reached again.

### P2 — Followup

- **Stop-tap race: unit test**
  Manual test T1 (rapid stop tap with throttled network) is sufficient for v1.6. A proper unit test requires mocking the VehicleRadarService — defer to next sprint.
  **Deferred from:** /autoplan (2026-04-11)

- **vehicleFetchCount: unit test**
  Test that prompt fires at exactly counts 5 and 20, and never again after 20. Deferred — manual verification with @AppStorage reset is sufficient for v1.6.
  **Deferred from:** /autoplan (2026-04-11)

## App Store Submission

### P1 — Active (v1.5)

- **Upload screenshots to App Store Connect**
  6 files at `screenshots/final/{en,de}/`. Upload as iPhone 6.7" (`IPHONE_67`).
  Via ASC web UI (drag-and-drop) or asc CLI if supported.

- **Archive + upload binary**
  Xcode → Product → Archive (BerlinTransportMap scheme, Any iOS Device) → Organizer → Distribute → App Store Connect.

- **Submit v1.5 for App Store review**
  After binary processes on ASC (~15-30 min). Encryption compliance: No.

### P2 — Followup

- **TestFlight beta before future major releases**
  For v1.5 the app is ready and submission is immediate. For future major releases (significant UI changes), consider TestFlight beta first.
  **Deferred from:** /autoplan (2026-04-11)

- **asc CLI screenshot automation script**
  Write a script using `asc screenshots upload` to automate the 6-screenshot upload for future releases. For v1.5, manual ASC web upload is fine.
  **Deferred from:** /autoplan (2026-04-11)

## Infrastructure / Risk

### P3 — Strategic

- **VBB API resilience**
  `v6.vbb.transport.rest` is community-hosted by @derhuerst with no SLA. If the API changes or rate-limits, all departures break for all users. Options: (a) negotiate VBB partnership, (b) mirror via GTFS-RT official feed, (c) add offline fallback with last-known data. This is the existential risk for the app.
  **Flagged by:** /autoplan CEO review (2026-04-11)

- **Portfolio consolidation: MyStop Berlin + Berlin Transport Map**
  Two apps in the same portfolio targeting Berlin transit. Consider whether to consolidate or differentiate more clearly (real-time positions vs stop departures). Bring to /office-hours.
  **Flagged by:** /autoplan CEO review (2026-04-11)

## Favorites

### P2 — Followup

- **Route replay implementation**
  Saved routes currently show a "Route Replay Unavailable" alert. To implement: store departure/arrival times and leg details in the Favorite model, then recreate the route object from stored data on tap.

## Completed

- **First-launch welcome overlay (3 screens)** — Completed v1.5 (2026-04-09)
- **tvOS compatibility guards** — Completed v1.5 (2026-04-09)
- **Route favorites silent failure fix** — Completed v1.5 (2026-04-09)
- **Location auto-center on first grant** — Completed v1.5 (2026-04-09)
- **VoiceOver accessibility hint fix (route favorites)** — Completed v1.5 (2026-04-09)
- **iPad WelcomeOverlay card maxWidth: 560** — Already done in v1.5 (WelcomeOverlayView.swift:67), confirmed by /autoplan code audit (2026-04-11)
