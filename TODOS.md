# TODOS

## OnboardingView (12-screen, v1.6+)

### P1 — Active (v1.7)

- ~~**Tip purchase: disabled state during async + error state on failure**~~ `.disabled(store.state == .loading)` fixed (2026-04-13), commit `0030fc1`. Error state on failure (`store.state == .failed`) still open → move to P2.

- ~~**Location permission denial: silent dead end on ProcessingScreen**~~ Fixed by /qa on main (2026-04-13). `ProcessingScreen` already shows "Location off — map starts at Alexanderplatz. Enable in Settings → Privacy anytime." when `.denied`/`.restricted`.

- ~~**MiniDepartureBoard: hardcoded sample data presented as "right now"**~~ Fixed by /qa on main (2026-04-13), commit `547c014`

- ~~**SwiftData save: conditional confirmation on ValueDeliveryScreen**~~ Fixed by /qa on main (2026-04-13). Save now happens on advance to step 8 (before `ValueDeliveryScreen` renders); subtitle shows "Stops saved to Favorites ✓" on success or "Couldn't save your stops — re-add them in Favorites." on failure.

- ~~**Back button missing from all onboarding screens**~~ Fixed by /qa on main (2026-04-13). `chevron.left` button present for `step > 0 && step != 6`, skips ProcessingScreen when going back from step 7.

### P1 — Product Improvement
- **ValueDeliveryScreen: show real live departures instead of hardcoded sample data**
  After saving stops to Favorites, `ValueDeliveryScreen` shows fake `sampleDepartures`. This misses the strongest "aha moment" in a transit app — seeing your actual stops, live.
  Fix: Fetch real BVG departure data for `selectedStops` async on screen appear; show real arrivals. Loading spinner while fetching. This requires async network call in onboarding.

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
  Add `@State private var stopsSaved = false` guard in OnboardingView. Currently safe (called once at step==8) but defensively correct.

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

### P0 — BLOCKING (ship before v1.7 work)

- **Submit v1.5 to App Store — DO THIS FIRST**
  App has 0 users. v1.7 widget is useless with no install base. Every day without shipping is a day without feedback informing feature decisions. Run the CLAUDE.md pre-submission checklist, archive, and submit.
  **Escalated to P0 by:** /plan-eng-review (2026-04-14). Outside voice and eng review agree: shipping dominates in expected value over any feature work.

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

## v1.7 Features

### P1 — Active

(none — multi-city foundation shipped in v1.7; see ## Completed)

### P1 — Deferred to v1.8 (multi-city follow-ups)

- **Map header city pill** — Spec'd in autoplan design review (decision row 29) as ship-blocking but deferred to v1.8 since the navigation-bar title already shows the city name. Pattern: `[8pt accent dot] [City name (.fontDesign(.rounded))] [chevron.down]` floating top-leading below safe area. Tap opens picker.
- **API endpoint validation matrix** — `scripts/validate-city-endpoints.sh` to curl every endpoint type for Munich + Hamburg before flipping their `supportsRadar`/`supportsEvents` to `true` in CityConfig. Currently all non-Berlin cities run in departures-only mode.
- **Onboarding multi-city pass** — Welcome overlay still says "Watch Berlin transit", demo stops are Berlin-named, testimonials Berlin-specific. Codex/subagent flagged 11 hardcoded surfaces. Best done after API matrix runs and city pill ships.
- **Departures Mode visual taxonomy** — Non-radar cities should look deliberately different from Berlin (no live pulse, no vehicle layer, capability chip in pill, slightly larger stop dots). Currently they look like Berlin with missing data.
- **Trademark review on transit authority colors** — BVG/MVG/HVV/RMV/KVB/VVS/VRR/DVB/LVB/VAG accent colors ship without licenses. Functional color usage is hard to claim trademark on, but worth a legal pass before promoting non-Berlin cities.
- **TransportMapView extraction** — 1874 lines and growing. Extract `MapHeaderPill`, `EventsCard`, `WelcomeOverlay` integration, and the `onChange(cityManager)` data-clearing block. Mechanical not architectural.

### P3 — v1.9+ (gated on distribution data)

- **Re-enable Stuttgart, Düsseldorf, Dresden via alternative APIs** — v1.7 hides these 3 cities (`supportsDepartures: false`) because `v6.db.transport.rest` returns HTTP 500 on every `/stops/{id}/departures` call for VVS, VRR, and DVB. The community-maintained API does not proxy those HAFAS backends reliably. Per-city probe (commit `a00cf11`) confirmed every sampled stop fails.

  **Alternative APIs verified working (probed 2026-05-02):**

  | City | API | Format | Sample endpoint |
  |------|-----|--------|-----------------|
  | Stuttgart (VVS) | EFA-BW | XSLT JSON | `https://www.efa-bw.de/nvbw/XSLT_DM_REQUEST?type_dm=stop&...&outputFormat=JSON&useRealtime=1` |
  | Stuttgart (VVS) — alt | `www3.vvs.de` | XSLT JSON | `https://www3.vvs.de/mngvvs/XSLT_DM_REQUEST?...` |
  | Düsseldorf (VRR) | EFA-VRR | XSLT JSON | `https://efa.vrr.de/standard/XSLT_DM_REQUEST?...` |
  | Dresden (DVB) | DVB widgets | DVB JSON | `https://webapi.vvo-online.de/dm?stopid=...` |

  **Engineering scope (~7 solo days):**
  - EFA protocol adapter (Stuttgart + Düsseldorf share format) — 2 days
  - DVB widget adapter (Dresden) — 1 day
  - Response normalization to `TransportStop`/`TransportDeparture` — 1 day
  - Per-city protocol routing in `TransportService` — 0.5 day
  - Per-protocol search + departures (radar where available) — 1 day
  - Tests + per-city smoke tests + extend `scripts/validate-city-endpoints.sh` — 1.5 days
  - Total ~1,400 LOC

  **Decision gate:** invest only if v1.8 distribution sprint shows non-Berlin demand ≥ 30 dl/mo for 60 days (per pass-3 audit row 25). 96 dl/mo at v1.7 ship gives no evidence Stuttgart/Düsseldorf/Dresden specifically have demand. Building a week of code for cities no one is asking for is exactly the premature optimization pass-3 CEO review warned against.

  **Cheaper interim recovery:** `scripts/validate-city-endpoints.sh` runs weekly during v1.8. If `v6.db.transport.rest` recovers for any of the 3, flip `supportsDepartures: true` — zero code change.

### P1 — Active (legacy, completed in earlier release)

- **WidgetKit extension — DepartureWidget** (shipped in v1.7)

- **Commute Alerts — CommuteAlertManager** (shipped in v1.7)

### P2 — Followup

- **Commute Alerts live-data upgrade**
  Current v1.7 implementation uses fixed scheduled time as estimate. Upgrade: use URLSession background download task to fetch actual departure time the night before and update the notification content with the live departure time. This is what Transit App does.
  **Deferred from:** /plan-eng-review (2026-04-14). Needs real users with saved Favorites before prioritizing.

- **Events Map Card — find a valid data source**
  `api.berlin.de/events/` is unreachable (confirmed 2026-04-14). `EventsService.swift` code exists and is correct. Need a valid Berlin events API (Eventbrite API, KulturnetzBerlin, or Berlin.de official). Once data source confirmed, UI build is ~2h.
  **Dropped from v1.7 by:** /plan-eng-review (2026-04-14).

## Favorites

### P2 — Followup

- **Route replay implementation**
  Saved routes currently show a "Route Replay Unavailable" alert. To implement: store departure/arrival times and leg details in the Favorite model, then recreate the route object from stored data on tap.

## Completed

- **Multi-city foundation (10 German cities)** — Shipped in v1.7 (2026-04-28). `CityConfig` model with per-city `supportsRadar`/`supportsEvents`/`supportsRoutes` flags; `CityManager` persists selection; `ServiceContainer.updateCity` is async + propagates to `TransportService`/`RouteService`/`VehicleRadarService`/`OfflineStopsDatabase`/`PredictiveLoader`/`MapTilePreloader`/widget; `OfflineStopsDatabase` is per-city actor with namespaced cache + per-city grid + searchLocations cityId guard; `Favorite` carries `cityId` with per-`(stopId,cityId)` dedup; `WidgetSavedStop` carries `cityId+apiBaseURL` for per-stop API resolution; `CommuteAlert` carries `cityId`; deep links carry `?city=` and switch city before opening. `PRODUCT_DISPLAY_NAME` changed to "Transit Map". 22 new unit tests pass. **Completed:** v1.7 (2026-04-28).
- **Multi-city race fixes** — Shipped in v1.7 (2026-04-28). City switch now cancels in-flight `vehiclesLoadTask`/`stopsLoadTask` in `TransportMapView.onChange`; deep-link city switch awaits `updateCity` before opening departures sheet; `OfflineStopsDatabase.downloadAndCache` snapshots `currentCity` and aborts if it changes mid-download (prevents Berlin stops from being written to Munich cache); `searchLocations` short-circuit guarded by `activeCityId`. **Completed:** v1.7 (2026-04-28).
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
