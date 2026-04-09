<!-- /autoplan restore point: /Users/rd/.gstack/projects/dautovri-berlin-realtime-map/main-autoplan-restore-20260409-190247.md -->

# Berlin Transport Map — Feature Plan

**Branch:** main | **Date:** 2026-04-09 | **Scope:** WelcomeOverlay + tvOS Compatibility

---

## Summary

Two features shipping together:

1. **First-Launch Welcome Overlay** — 3-screen onboarding flow shown once on first launch. Screens: Welcome → Features → Location Priming. Gated by `@AppStorage("hasSeenWelcome")`.

2. **tvOS Compatibility** — Full `#if !os(tvOS)` guard pass across all views to make the app build and run on Apple TV. Includes toolbar rearrangement (bottom → top bar), context menu for Favorites delete, removal of iOS-only APIs (`requestReview`, `MapUserLocationButton`, `ShareLink`, `navigationBarTitleDisplayMode`).

---

## Changes

### New Files
- `BerlinTransportMap/Views/WelcomeOverlayView.swift` — 3-page onboarding overlay with page dots, reduce-motion support, location permission request on final screen.

### Modified Files
- `ContentView.swift` — Adds `@AppStorage("hasSeenWelcome")`, overlays `WelcomeOverlayView` on `TransportMapView` until dismissed, animated fade-out.
- `TransportMapView.swift` — tvOS guards: `requestReview`, `MapUserLocationButton`, `navigationBarTitleDisplayMode`, bottom toolbar → top bar for tvOS.
- `FavoritesView.swift` — tvOS guards: adds `contextMenu` for delete (works everywhere), guards `swipeActions` and `navigationBarTitleDisplayMode`.
- `SettingsView.swift` — tvOS guard: `navigationBarTitleDisplayMode`.
- `BerlinTransportMapAboutView.swift` — tvOS guards: `navigationBarTitleDisplayMode`, `ShareLink`, background color (`Color.black` vs `systemBackground`).
- `BerlinTransportMapHelpCenterView.swift` — tvOS guards: `navigationBarTitleDisplayMode` in two views.
- `TipJarView.swift` — tvOS guard: `navigationBarTitleDisplayMode`.

---

## Goals

- New users get a warm first-launch experience that explains the app and primes location permission.
- App compiles and runs on tvOS (AppleTVNetworkInfo companion strategy — same portfolio).
- Zero regression on iOS.

---

## Open Questions

- Should the welcome overlay also show on iPad/Mac Catalyst?
- Does the tvOS toolbar placement (top bar with Favorites + Settings buttons) match tvOS HIG?
- Is `requestLocationPermission()` on the WelcomeOverlay safe when called on tvOS (tvOS has no location)?

---

---

## Phase 1: CEO Review — SELECTIVE EXPANSION (Run 2, post-fixes)

### 0A: Premise Challenge

| Premise | Status | Notes |
|---------|--------|-------|
| First-launch onboarding improves user activation | ✅ Valid | Standard for utility apps. Users don't know this is live positions, not timetables. Location priming at onboarding is correct timing. |
| `@AppStorage("hasSeenWelcome")` is the right gate | ✅ Valid | Simple, works. Persists across sessions, resets on app delete. Magic string `"hasSeenWelcome"` isn't in a constants file — minor. |
| Location permission is worth requesting in onboarding | ✅ Valid | Centering the map on user position is the #1 first-run UX win for a transit map. |
| tvOS needs `#if !os(tvOS)` guards for iOS-only APIs | ✅ Valid | `navigationBarTitleDisplayMode`, `requestReview`, `MapUserLocationButton`, bottom toolbar — all iOS-only. |
| Scattering `#if !os(tvOS)` is the right approach | ⚠️ Debatable | A platform modifier or view wrapper would be cleaner. For 8 files it's pragmatic. Accepted under P5 (explicit > clever). |

### 0B: Existing Code Leverage

| Sub-problem | Existing code |
|-------------|--------------|
| First-launch gate | `@AppStorage("darkMode")` pattern already established in ContentView |
| Location permission | `CLLocationManager` — but NOT currently used anywhere else in the app (map shows city-wide, not user-centered) |
| Session/activation tracking | `ActivationMetricsService.shared` — exists but NOT wired to welcome flow |
| tvOS toolbar | New pattern: `ToolbarItemGroup(.topBarLeading)` for tvOS, no prior art in repo |

### 0C: Dream State

```
CURRENT:
  Cold launch → TransportMapView immediately
  No onboarding, no location priming, 0% location grant rate from onboarding

THIS PLAN:
  Cold launch → 3-screen WelcomeOverlay → TransportMapView
  Location primed. tvOS builds.

12-MONTH IDEAL:
  WelcomeOverlay tracks activation metrics (grant rate, drop-off screen)
  A/B testable overlay content
  tvOS has a tvOS-native onboarding (focus-based, no location screen)
```

### 0C-bis: Alternatives

| Approach | Effort | Risk | Pros | Cons |
|----------|--------|------|------|------|
| Current: Full overlay (3 screens) | Low | Low | Rich first impression, location priming | tvOS mismatch on location screen |
| Tip overlay (1 screen) | Lower | Lower | Less intrusive | Misses location priming opportunity |
| No onboarding | Zero | Zero | Nothing to break | Users never learn about live tracking feature |

Auto-decided: current approach ✅ (P1 — completeness)

### 0D: Scope Analysis (SELECTIVE EXPANSION mode)

**In scope — holding as-is:**
- 3-screen WelcomeOverlay on iOS
- tvOS compatibility guards across 8 views

**Expansion opportunities surfaced:**
- `ActivationMetricsService` wiring (track welcome_viewed, welcome_dismissed, location_granted_from_onboarding) — very low effort, high signal
- tvOS-specific welcome content (skip location screen, show focus-based UX tips)

**Critical bugs to fix (not expansions — correctness issues):**
1. WelcomeOverlayView shown on tvOS with location screen — needs `#if !os(tvOS)` in ContentView or within overlay
2. `CLLocationManager` immediately deallocated — needs to be held as `@State private var locationManager`

### 0E: Temporal Interrogation

| Time | State |
|------|-------|
| Hour 1 | Build passes on iOS. WelcomeOverlay appears on first launch. |
| Hour 1 | Location permission dialog may NOT appear (CLLocationManager bug) |
| Hour 2 | tvOS build: WelcomeOverlay shown with iOS location screen — UX broken |
| Hour 6+ | User installs, sees overlay, taps "Allow Location" — nothing happens silently |

### 0F: Mode Confirmation

SELECTIVE EXPANSION — confirmed. Holding scope, surfacing 2 expansion opportunities, fixing 2 bugs.

### Error & Rescue Registry

| Error | Trigger | Catch | User sees | Tested? |
|-------|---------|-------|-----------|---------|
| CLLocationManager dealloc | `requestLocationPermission()` called | Silent (nothing happens) | Nothing — dialog never appears | ❌ No |
| Location denied by system | User denies location | None (overlay dismisses) | Map without user location | ✅ Handled (onSkip path) |
| WelcomeOverlay on tvOS | First launch on Apple TV | None | iOS-style location screen | ❌ No guard |

### Failure Modes Registry

| Mode | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| CLLocationManager deallocated, location never requested | High | Medium — users never get location centering | Fix: store as @State |
| WelcomeOverlay tvOS UX mismatch | Certain (no guard) | Medium — bad tvOS UX | Fix: `#if !os(tvOS)` in ContentView |
| `hasSeenWelcome` key typo in future refactor | Low | Medium — all users see overlay again | Mitigation: extract to constant |

### What Already Exists

- `@AppStorage` pattern: ContentView.swift already has `darkMode` and `useSystemTheme`
- Activation tracking: `ActivationMetricsService` already tracks sessions, stop opens, favorite saves
- Location: NOT currently used anywhere in the app's main flow

### NOT In Scope

- A/B testing the overlay content
- Analytics on drop-off screen
- tvOS-native onboarding UI (separate effort)

### Dream State Delta

This plan gets us to: first-run experience + tvOS build.
Gap to 12-month ideal: no onboarding analytics, tvOS has iOS location screen.

### CEO Completion Summary (Run 1 — pre-fixes)

| Section | Finding | Severity |
|---------|---------|----------|
| Premises | All valid, 1 debatable (guards approach) | — |
| Bugs | CLLocationManager dealloc, tvOS location screen | 🚨 Critical |
| Expansion | ActivationMetricsService wiring | 💡 Optional |
| Scope | Holding. 2 bugs to fix before ship. | — |

---

### CEO Dual Voices — Run 2 (post-fixes)

**CODEX SAYS (CEO — strategy challenge):**

| Severity | Finding |
|----------|---------|
| Critical | 3-screen modal delays the "aha" moment — live vehicles are the hook, not the tutorial |
| High | tvOS scope unvalidated — "same portfolio" is internal logic, not customer pull |
| High | Plan stale — both critical bugs already fixed; review was tracking solved noise |
| High | Activation claims made without measurement (ActivationMetricsService deferred) |
| Medium | `hasSeenWelcome` boolean lacks versioning — brittle at 6 months |

**CLAUDE SUBAGENT (CEO — strategic independence):**

| Severity | Finding |
|----------|---------|
| Medium | Onboarding premise unvalidated — no D1 retention data to prove modal improves activation |
| High | tvOS demand not validated by any usage data |
| Medium | No analytics loop — can't know if overlay helped |
| Medium | Alternative UX patterns (contextual tooltips, empty-state) not seriously evaluated |
| Low | Portfolio cannibalization risk with MyStop Berlin |

**CEO DUAL VOICES — CONSENSUS TABLE:**
```
═══════════════════════════════════════════════════════════════
  Dimension                           Claude  Codex  Consensus
  ──────────────────────────────────── ─────── ─────── ─────────
  1. Premises valid?                   ⚠️Med   ❌Crit  CONFIRMED concern
  2. Right problem to solve?           ⚠️Med   ❌Crit  CONFIRMED concern
  3. Scope calibration (tvOS)?         ❌High  ❌High  CONFIRMED concern
  4. Alternatives explored?            ⚠️Med   ❌Crit  CONFIRMED concern
  5. Competitive/market risks?         ⚠️Low   —      N/A
  6. 6-month trajectory (analytics)?   ⚠️Med   ❌High  CONFIRMED concern
═══════════════════════════════════════════════════════════════
5/6 dimensions flagged by at least one model. 4 CONFIRMED (both models agree).
```

**Auto-decisions from CEO Run 2:**

- Premise #1 (modal overlay): User confirmed in premise gate. Holding. Concerns surfaced as TASTE DECISION at final gate.
- Premise #4 (tvOS): User confirmed. Holding scope. Surfaced as TASTE DECISION at final gate.
- Analytics wiring: Both models recommend. Previous autoplan deferred. → **USER CHALLENGE** (surfaced at final gate).
- `hasSeenWelcome` versioning: Minor improvement. → TASTE DECISION.
- Plan staleness: Fixed — both critical bugs are confirmed resolved in current code (verified in this session).

---

## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|----------------|-----------|-----------|---------|
| 1 | CEO | Approach: 3-screen overlay | Mechanical | P1 — completeness | Full onboarding > stripped-down version | Tip overlay (1 screen) |
| 2 | CEO | Scope: hold, don't expand analytics | Mechanical | P3 — pragmatic | Bug fixes first; analytics is an expansion | Add ActivationMetrics tracking |
| 3 | Design | "Browse Berlin" → "Not now" | Mechanical | P5 — explicit | Label reads as primary CTA, not skip | Keep "Browse Berlin" |
| 4 | Design | Add `.frame(maxWidth: 400)` on buttons | Mechanical | P1 — completeness | Full-width buttons look broken on iPad | Skip iPad fix |
| 5 | Design | Use Theme.swift instead of AppTheme shim | Mechanical | P4 — DRY | Two design token systems in one project | Keep private shim |
| 6 | Eng | CLLocationManager: local var → @State | Mechanical | P1 — correctness | Silent failure otherwise | Leave as local var |
| 7 | Eng | ContentView: add #if !os(tvOS) around WelcomeOverlay | Mechanical | P1 — correctness | Broken UX on Apple TV | Show overlay on tvOS |
| 8 | Design R2 | Screen 2 heading: add "Here's what you can do" | Mechanical | P5 — explicit | No heading = journey momentum drops | Skip heading |
| 9 | Design R2 | Transit icons: add .accessibilityHidden(true) | Mechanical | P1 — correctness | Decorative icons noisy to VoiceOver | Leave icons announced |
| 10 | Design R2 | "Not now" tap target: add .padding(.vertical, 8) | Mechanical | P1 — completeness | Below 44pt minimum without padding | Leave as-is |
| 11 | Design R2 | Page dots: change to .accessibilityHidden(true) | Mechanical | P5 — explicit | Labeled non-interactive dots mislead VoiceOver | Keep accessibilityLabel |
| 12 | Eng R2 | Route favorites bug: fix or block .route type | Mechanical | P1 — correctness | Silent broken behavior in production | Ship broken |
| 13 | Eng R2 | Location denied: check auth status before dismiss | Mechanical | P1 — correctness | Silent no-op when location already denied | Ignore denied case |
| 14 | Eng R2 | iPad card: add .frame(maxWidth: 560) on card VStack | Mechanical | P1 — completeness | Card stretches, button doesn't — visually broken | Leave uncapped |

**Taste Decisions (surfaced at final gate):**
- T1: Modal-first vs. show-map-first UX approach (both models question, user confirmed premise #1)
- T2: tvOS demand validation (both models question, user confirmed premise #4)
- T3: hasSeenWelcome versioning ("hasSeenWelcomeV1" vs. plain key)
- T4: Location dismiss timing (call onDismiss() before vs. after requestWhenInUseAuthorization())
- T5: Screens 2/3 entrance animation (add staggered spring animation to match screen 1)
- T6: ScrollView wrapper for Dynamic Type / landscape resilience
- T7: Stop-tap async race fix (cancel prior task before launching new)
- T8: centerOnUserLocation() auto-called after permission grant (dead code path)
- T9: iPhone SE Spacer(minLength: 0) — defensiveness vs. minimal change

**USER CHALLENGE:**
- UC1: ActivationMetricsService wiring (both models recommend now; previous autoplan deferred)

---

## Cross-Phase Themes

**Theme: "The location promise is broken end-to-end"** (flagged CEO, Design, Eng)
- CEO: location priming at onboarding assumed but not validated
- Design: `onDismiss()` fires before system dialog — jarring UX
- Eng: overlay's CLLocationManager isolated from app pipeline; `centerOnUserLocation()` is dead code after grant
- High-confidence signal. The "Allow Location" button promises centering on user's position. That centering never happens automatically.

**Theme: "No measurement loop"** (flagged CEO, Design phases)
- CEO (both models): activation claim made without measurement
- Design (Codex): binary gate with zero drop-off visibility
- Same root: `ActivationMetricsService` exists but is not wired to onboarding events.

**Theme: "Blast radius wider than the plan"** (flagged Eng)
- Route favorites broken (FavoritesView.swift:122) — pre-existing, in blast radius, not in plan
- Stop-tap async race (TransportMapView.swift:535) — pre-existing, not in plan

---

## Phase 2: Design Review Summary (Run 1 — pre-fixes, see below for Run 2)

| Dimension | Score | Action |
|-----------|-------|--------|
| Information hierarchy | 8/10 | — |
| Interaction states | 6/10 | Minor: add page VoiceOver announcement |
| User journey | 8/10 | Fix: rename "Browse Berlin" → "Not now" |
| AI slop risk | 9/10 | — |
| Responsiveness | 5/10 | Fix: add maxWidth cap for iPad |
| Accessibility | 6/10 | Fix: page dot a11y labels |
| Design system | 5/10 | Fix: remove AppTheme shim, use Theme.swift |

---

## Phase 2: Design Review — Run 2 (post-fixes, dual voice)

**CODEX SAYS (design — UX challenge):**
- Information hierarchy serves the developer, not the rider — modal blocks the product's payoff (live map)
- No interaction states: location flow is one-shot happy path only; denied/restricted case produces silent failure
- Responsive strategy is accidental — Spacer-based layout, no ScrollView, will break under Dynamic Type and landscape
- Accessibility partially specified — decorative icon strip not hidden from VoiceOver (WelcomeOverlayView.swift:84)
- Page dots have labels but are non-interactive — misleading to VoiceOver users
- Analytics hole: can't measure drop-off or test variants

**CLAUDE SUBAGENT (design — independent review):**
- Critical: `onDismiss()` fires synchronously with `requestLocationPermission()` — overlay fades while system dialog appears. Jarring UX.
- High: Screens 2 and 3 have zero entrance animation; after animated screen 1 this is a hard quality drop
- Medium: Screen 2 (`WelcomeFeaturesContent`) has no heading — journey momentum drops
- Medium: Feature row icons hardcoded `.blue` — abandons the Berlin brand palette from screen 1
- Medium: "Not now" button lacks minimum tap target (no padding, no frame)
- Medium: Page dots declare `accessibilityLabel` but are non-interactive — fix is `.accessibilityHidden(true)` on the HStack

**DESIGN LITMUS SCORECARD:**
```
═══════════════════════════════════════════════════════════════
  Dimension                           Score   Key finding
  ──────────────────────────────────── ─────── ─────────────────
  1. Information hierarchy             6/10   Modal blocks live map aha
  2. Interaction states                5/10   Location deny = silent failure
  3. Emotional arc                     6/10   Screen 2 loses momentum
  4. UI specificity                    6/10   Screen 2 icons generic blue
  5. Responsiveness                    5/10   No ScrollView, Spacer-based
  6. Accessibility                     6/10   Icon strip, page dots issues
  7. Overall                           6/10   —
═══════════════════════════════════════════════════════════════
```

**Auto-decisions from Design Run 2:**
- Location dismiss timing: TASTE DECISION (functional, UX slightly jarring — fix by calling `onDismiss()` first, then `requestLocationPermission()`)
- Screens 2/3 entrance animation: TASTE DECISION (quality improvement)
- Screen 2 heading: auto-decide YES — add "Here's what you can do" (P5: explicit)
- Transit icons VoiceOver: auto-decide YES — add `.accessibilityHidden(true)` to icon HStack (P1: correctness)
- "Not now" tap target: auto-decide YES — add `.padding(.vertical, 8)` (P1: completeness)
- Page dots: auto-decide YES — change to `.accessibilityHidden(true)` on HStack (both models agree, was misleading)
- ScrollView: TASTE DECISION (defer — larger change)

---

## Phase 3: Eng Review Summary (Run 1 — pre-fixes)

Architecture:
```
WelcomeOverlayView
  ├── @State currentPage, appeared
  ├── CLLocationManager() ← LOCAL (BUG: must be @State)
  └── AppTheme shim ← diverges from Theme.swift

ContentView
  └── .overlay { WelcomeOverlayView }  ← NO #if !os(tvOS) guard (BUG)
```

| Finding | Severity | Fix |
|---------|----------|-----|
| CLLocationManager dealloc | 🚨 | Store as @State private var locationManager |
| No tvOS guard in ContentView | 🚨 | Add #if !os(tvOS) around overlay |
| AppTheme shim | ⚠️ | Replace with Theme.swift tokens |
| Magic string "hasSeenWelcome" | ℹ️ | Acceptable |

---

## Phase 3: Eng Review — Run 2 (post-fixes) [subagent-only — Codex timed out]

**Architecture ASCII Diagram (current state):**
```
ContentView
  ├── @AppStorage("hasSeenWelcome") ← persists via UserDefaults
  ├── #if !os(tvOS)
  │   └── .overlay { WelcomeOverlayView(onDismiss:) }
  └── TransportMapView
        ├── LocationManager (shared singleton)
        ├── CLLocationManager (app's main, with delegate)
        ├── Two Task polling loops (GTFS-RT)
        └── FavoritesView (sheet)
              └── handleSelectFavorite()
                    ├── .stop → TransportStop (✅ works)
                    └── .route → Route(legs: []) ← BROKEN

WelcomeOverlayView
  ├── @State locationManager = CLLocationManager() ← isolated, no delegate
  ├── requestLocationPermission() → locationManager.requestWhenInUseAuthorization()
  └── onDismiss() called SYNCHRONOUSLY with permission request
```

**CLAUDE SUBAGENT (eng — independent review) [subagent-only]:**

| Finding | File:Line | Severity | Fix |
|---------|-----------|----------|-----|
| Overlay's CLLocationManager isolated from app pipeline | WelcomeOverlayView.swift:14, 67 | High | Inject shared LocationManager or use callback |
| Route favorites completely broken (legs: []) | FavoritesView.swift:122-124 | 🚨 High | Store route coordinates in Favorite model |
| Location denied → silent no-op, no Settings redirect | WelcomeOverlayView.swift:67 | High | Check auth status, disable button or link to Settings |
| iPad card not width-capped (card stretches, button doesn't) | WelcomeOverlayView.swift:61 | Medium | Add .frame(maxWidth: 560) on card VStack |
| iPhone SE: Spacer() without minLength can clip | WelcomeOverlayView.swift:22 | Medium | Add Spacer(minLength: 0) |
| vehicleFetchCount grows unbounded, review never fires >20 | TransportMapView.swift:679 | Medium | Cap at 20 or use time-based trigger |
| FavoritesService recreated on every load | FavoritesView.swift:93 | Medium | Initialize once in .task |
| Polling loops only cancelled via .task, onDisappear is incomplete | TransportMapView.swift:313 | Medium | Low risk now, latent in future refactor |
| localizedDescription surfaced to UI | FavoritesView.swift:103 | Low | Sanitize to user-facing strings |

**Test diagram — gaps:**
```
Flow                                    Test exists?  Gap
──────────────────────────────────────  ───────────── ──────────────────────
Welcome overlay first launch (iOS)      ❌ No         Unit/UI test needed
Location grant via overlay              ❌ No         Integration test
Location denied edge case              ❌ No         Unit test on auth check
Welcome overlay NOT shown on tvOS      ❌ No         Platform test
Route favorites selection (broken)     ❌ No         Would have caught this
Stop favorites selection                ❌ No         Manual only
hasSeenWelcome persistence             ❌ No         UserDefaults integration
tvOS toolbar layout                    ❌ No         Visual regression
```

**CODEX SAYS (eng — architecture challenge):**

| Finding | File:Line | Severity |
|---------|-----------|----------|
| Route favorites nonfunctional — dummy Route(legs:[]) never re-centers map | FavoritesView.swift:121 | 🚨 High |
| Async race: stop tap spawns untracked Tasks writing shared state | TransportMapView.swift:535/547 | 🚨 High |
| Location onboarding disconnected — `centerOnUserLocation()` is dead code after overlay | WelcomeOverlayView.swift:34 | 🚨 High |
| TransportMapView god view — polling, location, routing, analytics, sheets all in one | TransportMapView.swift:56 | ⚠️ Medium |
| errorMessage written from multiple async paths, never surfaced to UI | TransportMapView.swift:74 | ⚠️ Medium |

**ENG DUAL VOICES — CONSENSUS TABLE:**
```
═══════════════════════════════════════════════════════════════
  Dimension                           Claude  Codex  Consensus
  ──────────────────────────────────── ─────── ─────── ─────────
  1. Architecture sound?               ⚠️High  ❌High  CONFIRMED (isolation+god view)
  2. Test coverage sufficient?         ❌      ❌      CONFIRMED (no onboarding tests)
  3. Performance risks addressed?      ⚠️Med   ❌High  CONFIRMED (async race)
  4. Security threats covered?         ✅Low   ✅      CONFIRMED (clean)
  5. Error paths handled?              ❌High  ❌Med   CONFIRMED (silent failures)
  6. Deployment risk manageable?       ⚠️Med   ⚠️Med  CONFIRMED (route favorites broken)
═══════════════════════════════════════════════════════════════
5/6 confirmed. CRITICAL NEW BUG: stop-tap async race (Codex-only find).
```

**NOT in scope (deferred):**
- FavoritesService redesign (singleton vs. per-view)
- Routing feedback on location denial (links to Settings)
- Unit test harness for WelcomeOverlayView

**What already exists:**
- `LocationManager` wrapper: app has centralized location handling
- `ActivationMetricsService`: tracks sessions, stop opens, favorite saves — NOT wired to onboarding
- `@AppStorage` pattern: established in ContentView for darkMode/useSystemTheme

**Failure Modes Registry (updated):**

| Mode | Probability | Impact | Status |
|------|-------------|--------|--------|
| CLLocationManager dealloc | ~~High~~ FIXED | Medium | ✅ Fixed (this session) |
| WelcomeOverlay on tvOS | ~~Certain~~ FIXED | Medium | ✅ Fixed (this session) |
| Route favorites broken | High | High | ❌ PRE-EXISTING BUG |
| Location denied silent failure | Medium | Medium | ❌ Not addressed |
| iPad card stretches | High | Low | ❌ Not addressed |
| vehicleFetchCount unbounded | Low | Low | ❌ Pre-existing |
