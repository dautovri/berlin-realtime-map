# TODOS

## OnboardingView (12-screen, v1.6+)

### P1 — Active (v1.7)

- ~~**Tip purchase: disabled state during async + error state on failure**~~ `.disabled(store.state == .loading)` fixed (2026-04-13), commit `0030fc1`. Error state on failure (`store.state == .failed`) still open → move to P2.

- **Location permission denial: silent dead end on ProcessingScreen**
  `OnboardingView.swift:897-903` — `onNext()` called unconditionally after 1.5s regardless of authorization result.
  Fix: Check `CLAuthorizationStatus` on ProcessingScreen. If `.denied`, show: "Location off — map starts at Alexanderplatz. Enable in Settings → Privacy anytime."

- ~~**MiniDepartureBoard: hardcoded sample data presented as "right now"**~~ Fixed by /qa on main (2026-04-13), commit `547c014`

- **SwiftData save: conditional confirmation on ValueDeliveryScreen**
  `OnboardingView.swift:1035` — "These go straight to your Favorites ✓" shown before save verified.
  Fix: Re-query SwiftData on `ValueDeliveryScreen` appearance; show "Stops saved ✓" vs. "Couldn't save your stops — re-add them in Favorites."

- **Back button missing from all onboarding screens**
  9-step flow (post-cuts) with no back navigation. Users who misselect on step 2 are stuck.
  Fix: Add `<` chevron for `step > 0 && step != 6` (ProcessingScreen at step 6 cannot go back).

- ~~**Delete dead WelcomeOverlayView.swift**~~ Deleted by /qa on main (2026-04-13), commit `274c0ea`.

### P2 — Followup

- **Tinder card mechanic: wire swipe direction to personalization OR remove the screen**
  `OnboardingView.swift:573-688` — swipe direction not stored; same action on both directions. `SolutionScreen` already handles personalization from `PainScreen`. Four screens of friction with no payoff.
  Fix option A: Record swipe direction and feed into `selectedPains` for richer personalization.
  Fix option B: Remove the TinderCardScreen entirely (simpler, more honest flow).
  **TASTE DECISION — user decides at autoplan gate.**

- **TransitTypeScreen: persist selections OR remove the screen**
  `OnboardingView.swift:786-853` — `selectedTransitTypes` collected but never persisted or used.
  Screen promises "We'll highlight these on your map" — broken promise.
  Fix option A: Persist to `@AppStorage("preferredTransitTypes")`, wire to a future map filter.
  Fix option B: Remove the screen to eliminate the broken promise.
  **TASTE DECISION — user decides at autoplan gate.**

- **hasSeenWelcome key rename to hasSeenOnboardingV2**
  Existing users have `hasSeenWelcome = true` → skip the new 12-screen flow forever.
  Renaming would re-show onboarding to all retained users (good re-engagement OR annoying).
  **TASTE DECISION — user decides at autoplan gate.**

- **Hardcoded font sizes: replace with Dynamic Type**
  Multiple screens use `.font(.system(size: 34, weight: .bold))` / `.font(.system(size: 30, weight: .bold))`.
  Fix: Replace with `.font(.largeTitle.bold())` / `.font(.title.bold())`. Delay badge: add `.monospacedDigit()`.

- **CLLocationManager: wrap in @Observable @MainActor class**
  `OnboardingView.swift:220` — `CLLocationManager` passed as non-Sendable into child struct. Safe today; will error at Swift 6 strict concurrency.
  Fix: `@Observable @MainActor final class LocationPermissionManager { let manager = CLLocationManager() }`

- **saveSelectedStops: add idempotency guard**
  Add `@State private var stopsSaved = false` guard in OnboardingView. Currently safe (called once at step==11) but defensively correct.

- **ProcessingScreen: replace try? with Task.isCancelled check**
  `OnboardingView.swift:~965` — `try? await Task.sleep(...)` silently swallows cancellation.
  Fix: `try await Task.sleep(...) ; guard !Task.isCancelled else { return }`

- **Unit test harness for onboarding**
  No unit tests exist. Critical paths: `hasSeenWelcome` gate, stop save, location permission guard, tip purchase success/failure.
  **Deferred from:** /autoplan (2026-04-13, P3 — separate sprint)

- **ContentView #Preview: add ModelContainer**
  `ContentView` `#Preview` block crashes without `.modelContainer(for: [TransportStopFavorite.self], inMemory: true)`.

- **TipNudgeScreen: show inline error on `store.state == .failed`**
  `.disabled` guard added (commit 0030fc1). No error message on purchase failure — user sees nothing if StoreKit fails.
  Fix: Show inline "Purchase failed — try again." when `store.state == .failed`.

## Analytics

### P2 — Active

- **Review v1.5 onboarding funnel data before locking v1.7 scope**
  v1.5 had 3-screen onboarding with analytics. v1.6 has 12 screens. No baseline comparison done.
  Pull funnel data from ASC + any in-app events. If 3-screen completion was >80%, 12 screens may hurt.
  **Flagged by:** /autoplan CEO review (2026-04-13)

- **Define and instrument "aha moment"**
  First successful departure lookup after onboarding is the activation event. Instrument it.
  Build a 30-day retention check: what % of users who complete onboarding return on day 7?
  **Flagged by:** /autoplan CEO review (2026-04-13)

- **Post-onboarding activation path (first 60 seconds after onboarding)**
  What does the user see? Does the map load quickly? If VBB API is slow, no guidance exists.
  Define: what is the empty state on first map load? What does no-location look like?
  **Flagged by:** /autoplan CEO review (2026-04-13)

## TransportMap

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

### P2 — Elevated (was P3)

- **VBB API resilience — PROTOTYPE GTFS-RT FALLBACK**
  `v6.vbb.transport.rest` is community-hosted by @derhuerst with no SLA. If the API changes, rate-limits, or goes dark, all departures break for all users. Options: (a) negotiate VBB partnership, (b) mirror via GTFS-RT official feed, (c) add offline fallback with last-known data.
  **ELEVATED P3→P2 by:** /autoplan CEO review (2026-04-13). Existential dependency; prototype GTFS-RT fallback in next sprint.
  **Previously flagged by:** /autoplan CEO review (2026-04-11)

- **Portfolio consolidation: MyStop Berlin + Berlin Transport Map**
  Two apps in the same portfolio targeting Berlin transit. Consider whether to consolidate or differentiate more clearly (real-time positions vs stop departures). Bring to /office-hours.
  **Flagged by:** /autoplan CEO review (2026-04-11)

## Favorites

### P2 — Followup

- **Route replay implementation**
  Saved routes currently show a "Route Replay Unavailable" alert. To implement: store departure/arrival times and leg details in the Favorite model, then recreate the route object from stored data on tap.

## Completed

- **Stop-tap async race fix** — Implemented on main (2026-04-13). `guard selectedStop?.id == stop.id` guard at TransportMapView.swift:576 discards stale responses on rapid stop-tap.
- **vehicleFetchCount cap (bloat prevention)** — Implemented on main (2026-04-13). `if vehicleFetchCount < 21 { vehicleFetchCount += 1 }` at TransportMapView.swift:706.
- **FavoriteRow dead tap zone** — Fixed by /qa on main (2026-04-13), commit `bd9f39f`. `.contentShape(Rectangle())` added to HStack; `.accessibilityElement(children: .combine)` removed from VStack (was intercepting accessibility taps before the Button action).
- **Departure sheet star icon always empty** — Fixed by /qa on main (2026-04-13), commit `37c4bba`. Added `isFavorite` state with SwiftData `.task(id: stop.id)` query; star shows filled + disabled when stop already saved.
- **OnboardingView DemoScreen back/subtitle bugs** — Fixed by /qa on main (2026-04-13), commit `cf7fb2a`.
- **JourneyPlannerSheet route shows '0 min', no legs** — Fixed by /qa on main (2026-04-13), commit `791b4fa`. RouteService called `/trips` (vehicle lookup) instead of `/journeys` (route planning). Fixed endpoint, response models, and duration computation from leg times.
- **Duplicate stop favorites saved on onboarding** — Fixed by /qa on main (2026-04-13), commit `f45301c`. FavoritesService.saveStopFavorite had no dedup guard; added stopId predicate check before insert.
- **ProcessingScreen permanently stuck** — Fixed by /qa on main (2026-04-13), commit `53dd2b3`. `.task(id: processingComplete)` fired once at launch (step=0), never re-ran at step 6. Fixed to `.task(id: step)`.
- **MiniDepartureBoard fake 'right now' headline** — Fixed by /qa on main (2026-04-13), commit `547c014`.
- **TinderCardsScreen + TransitTypeScreen cut** — Completed (2026-04-13), commit `0030fc1`.
- **hasSeenWelcome → hasSeenOnboardingV2 rename** — Completed (2026-04-13), commit `0030fc1`.
- **Tip purchase disabled state during async** — Completed (2026-04-13), commit `0030fc1`.
- **First-launch welcome overlay (3 screens)** — Completed v1.5 (2026-04-09)
- **tvOS compatibility guards** — Completed v1.5 (2026-04-09)
- **Route favorites silent failure fix** — Completed v1.5 (2026-04-09)
- **Location auto-center on first grant** — Completed v1.5 (2026-04-09)
- **VoiceOver accessibility hint fix (route favorites)** — Completed v1.5 (2026-04-09)
- **iPad WelcomeOverlay card maxWidth: 560** — Already done in v1.5 (WelcomeOverlayView.swift:67), confirmed by /autoplan code audit (2026-04-11)
