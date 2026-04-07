<!-- /autoplan restore point: /Users/rd/.gstack/projects//main-autoplan-restore-20260407-081424.md -->

# Berlin Transport Map — /autoplan Full Review

**Branch:** main | **Commit:** aa35983 | **Date:** 2026-04-07 | **REPO_MODE:** solo

> **Re-run vs 2026-03-23 review (7afccd1).** Significant changes landed in `8763a42`: fatalError fixed ✅, dead Config code removed ✅, EventsService → actor ✅, OfflineStopsDatabase → actor ✅, CacheService.age() removed ✅, macOS Catalyst added. Full review updated below.

---

## Progress Since Last Review (7afccd1 → aa35983)

| Issue | In Last Review | Status |
|-------|---------------|--------|
| `fatalError` on ModelContainer failure | 🚨 High | ✅ Fixed — in-memory fallback added |
| Dead `Config.apiAuthorization` / `Env.apiAid` | ⚠️ Medium | ✅ Removed — `Config.swift` now has only `Env.overrideBaseURL` |
| `CacheService.age(of:)` always nil | ⚠️ Low | ✅ Removed entirely |
| `EventsService` not thread-safe (`@unchecked Sendable`) | ⚠️ Medium | ✅ Converted to `actor` |
| `OfflineStopsDatabase` not thread-safe | ⚠️ Medium | ✅ Converted to `actor` |
| `EventsService.shared` dead singleton | ℹ️ Low | ✅ Removed |
| `CacheService` still `@unchecked Sendable` | ⚠️ Open | ⚠️ Remains (see note below) |
| 8 embedded structs in `TransportMapView.swift` | ⚠️ Open | ⚠️ Remains (1471 lines, still 8 embedded) |
| 9 computed view properties in `TransportMapView` | ⚠️ Open | ⚠️ Remains (9 computed `some View`/`some MapContent`) |
| `HistoricalDataStorage` missing `final` | ℹ️ Open | ⚠️ Remains |
| Vehicle interpolation math untested | ⚠️ Open | ⚠️ Remains |
| `ConfigTests` testing dead code | ⚠️ Open | ✅ Updated — now tests `Env.overrideBaseURL` |
| macOS Catalyst support | New since last review | ✅ Added |

---

## Here's what I'm working with

## Here's what I'm working with

Berlin Transport Map is a **live iOS + macOS Catalyst app** (App ID 6757723208) showing real-time VBB vehicle positions on a MapKit map. Free with tip jar. Stack: Swift 6, SwiftUI, SwiftData, MapKit, VBB REST API `v6.vbb.transport.rest`. Architecture: single `TransportMapView` (1471 lines) as the coordinator, backed by a `ServiceContainer` singleton with 8 services. **UI scope: YES** — map-heavy with custom annotations, sheets, and status overlays. **DX scope: NO** — end-user iOS app.

---

## Phase 1: CEO Review — Strategy & Scope (Updated 2026-04-07)

### Step 0A: Premise Challenge

| Premise | Status | Verdict |
|---------|--------|---------|
| "Real-time vehicle positions" | ✅ True | `VehicleRadarService` (actor) polls `/radar` every 15–30s |
| "No account, no tracking" | ✅ True | No auth, no analytics SDK; `PrivacyInfo.xcprivacy` exists |
| "Full VBB network" | ✅ True | Offline stops database covers Berlin Brandenburg |
| "No third-party SDK" | ✅ True | All API calls are direct REST; no packages |
| "VBB API will remain stable and free" | ⚠️ RISK | `v6.vbb.transport.rest` is community-hosted by @derhuerst — unofficial, no SLA |
| "Privacy first — location is optional" | ✅ True | `LocationManager` requests only when-in-use; map works without GPS |
| "Config AID is used" | ✅ Resolved | Dead code removed; `Config` now only has `Env.overrideBaseURL` for testing |
| "macOS Catalyst works" | ✅ New in 8763a42 | Minimum window size, menu commands, notifications wired up |
| "try! fallback container is safe" | ⚠️ RISK | `BerlinTransportMapApp.swift:24` — `try! ModelContainer(for:schema, in-memory)` — documented as safe but still a force-try; worth a do-catch for correctness |

**GATE [premises needing confirmation — auto-decided P6]:** Community API risk accepted (cannot fix without VBB cooperation). `try!` on in-memory container is defensible (truly cannot fail) but cosmetically impure.

---

### Step 0B: Existing Code Leverage Map

| Sub-problem | Where it lives today | Quality |
|-------------|---------------------|---------|
| Real-time vehicle positions | `VehicleRadarService` (actor) | ✅ Excellent |
| Stop search + nearby | `TransportService` + `OfflineStopsDatabase` (actor) | ✅ Good |
| Departures | `VehicleRadarService.fetchDepartures()` + `TransportService` | ✅ Good |
| Route overlay | `RouteService` (@MainActor @Observable) | ✅ Good |
| Offline stop database | `OfflineStopsDatabase` (actor, 7-day cache TTL) | ✅ Thread-safe now |
| In-memory caching | `CacheService` (`@unchecked Sendable`, NSCache) | ⚠️ Thread-safe in practice; annotation still wrong |
| Predictive prefetch | `PredictiveLoader` + `UserPatternService` | ✅ Well structured |
| Prediction persistence | `PredictionService` + `HistoricalDataStorage` | ⚠️ `HistoricalDataStorage` not `final` |
| Events | `EventsService` (actor now) | ✅ Thread-safe; UI exposure still minimal |
| Favorites | `FavoritesService` + SwiftData `Favorite` | ✅ Simple, correct |
| Map tile warmup | `MapTilePreloader` | ✅ Smart perf optimization |
| macOS support | `BerlinTransportCommands`, Catalyst UI | ✅ New, works |

---

### Step 0C: Dream State Diagram

```
CURRENT STATE (aa35983)               NEXT UPDATE              12-MONTH IDEAL
───────────────────────────────  ─────────────────────  ──────────────────────────────
• Live on App Store                Break up TMV into     • Lock-screen widget (WidgetKit)
• iOS + macOS Catalyst             proper View structs   • Apple Watch companion
• 3 actors (VehicleRadar,          Add math unit tests   • Departure board for StandBy
  EventsService, OfflineStops)     Fix CacheService      • Siri shortcuts
• try! in-memory fallback          @unchecked            • Search from Spotlight
• 1471-line TransportMapView       Add final to          • Official VBB API (if/when)
• 8 embedded View structs          HistoricalDataStorage
• 9 computed view properties
• Excellent vehicle animation ✅
• macOS Catalyst added ✅
• All critical bugs fixed ✅
```

---

### Step 0D: Mode — SELECTIVE EXPANSION

Same as before. Live app on App Store. Fix pattern violations and wiring correctness. No new features until structural debt is paid.

**In scope (next update):**
1. `CacheService`: remove `@unchecked Sendable` — NSCache is thread-safe, class can be `Sendable` proper
2. `HistoricalDataStorage`: add `final`
3. `TransportMapView` computed view properties (9): extract to proper `View` structs per AGENTS.md
4. 8 embedded structs in `TransportMapView.swift`: move to own files
5. Vehicle interpolation math + `OfflineStopsDatabase.findStops` bounding-box: add unit tests
6. `try!` in `BerlinTransportMapApp.swift:24`: convert to `do-catch` with `preconditionFailure`

**Deferred:**
- Widget extension, Watch, Siri, StandBy, Official API migration

---

### Step 0E: Temporal Interrogation

**HOUR 1:** App launch → `BerlinTransportMapApp` `try!` on in-memory container. Documented safe but forced. If Apple changes the behavior of in-memory `ModelContainer` initialization in a future OS update, this becomes a crash. Use `do-catch` + `preconditionFailure("...")` to preserve intent while eliminating `try!`.

**HOUR 6:** `CacheService` called from multiple contexts. `@unchecked Sendable` suppresses Swift 6 strict concurrency checks for the whole class. NSCache is already thread-safe — removing `@unchecked` costs nothing and restores compiler enforcement.

**DAY 1:** `TransportMapView.swift` at 1471 lines with 8 embedded structs and 9 computed view properties. Each new feature or bug fix in this file requires reading or modifying a 1471-line context. Splitting out the embedded views is the highest-leverage structural move in the codebase.

---

### Section 1: Problem–Solution Fit ✅ (unchanged)

Strong product-market fit. BVG/VBB official apps don't show live map positions. macOS Catalyst now lets desktop users use the same app. No changes needed.

---

### Section 2: Error & Rescue Registry (Updated)

| Error Scenario | Current handling | Status |
|----------------|-----------------|--------|
| VBB REST API down | `TransportError.networkError` → status badge (stale/offline) | ✅ Good |
| SwiftData store corruption on launch | In-memory fallback with `try!` | ⚠️ Fixed but cosmetically ugly |
| Offline stops DB fails to load | Returns false → tries network download | ✅ Good |
| Location permission denied | Map works without GPS | ✅ Good |
| Events API unavailable | Silently dropped (EventsService catches internally) | ⚠️ Low — events not heavily surfaced |
| VehicleRadarService decode failure | Throws, vehicle load fails | ⚠️ No production logging |
| macOS Catalyst min-size violated | `.frame(minWidth:900, minHeight:600)` | ✅ Set |

---

### Section 3–10: (No material changes since 2026-03-23)

Per-section findings from 2026-03-23 review remain accurate for sections 3–10 except:
- Section 7 (Technical Debt): `Config.apiAuthorization`, `CacheService.age()`, `EventsService.shared`, `EventsService @unchecked` — all resolved. Remaining: `CacheService @unchecked Sendable`, `HistoricalDataStorage` not `final`.
- Section 8 (Security): Hardcoded AID removed. No remaining security issues.

---

### CEO Review Completion Summary (Updated)

| Area | Status | Critical Issues |
|------|--------|----------------|
| Problem-solution fit | ✅ Strong | — |
| Error handling | ✅ Improved | `try!` on in-memory container (low risk) |
| Distribution/ASO | ✅ Good | Already optimized |
| Monetization | ✅ Good | — |
| Platform leverage | ✅ Excellent | 3 actors, SwiftData, adaptive polling, macOS Catalyst |
| Scope risks | ⚠️ | 8 structs still in one 1471-line file |
| Technical debt | ⚠️ Low | `CacheService @unchecked`, `HistoricalDataStorage` not `final` |
| Security | ✅ Clean | Dead credential code removed |
| Privacy | ✅ Clean | — |
| API dependency risk | ⚠️ Strategic | Community VBB API, no SLA — acknowledged |

---

## Phase 2: Design Review (Updated 2026-04-07)

### Dimension 1: Visual Hierarchy — 8/10 (unchanged)

`Theme.swift` token system exists but `TransportMapView` still uses inline `Color.red.opacity(0.9)` etc. instead of `TransportTheme.Status.*`. Same finding as before — mechanical fix, blast radius is `TransportMapView.swift` only.

### Dimension 2: Spacing & Layout — 7/10 (unchanged)

No spacing token system. Visual output is good. Not a blocking issue.

### Dimension 3: Color & Dark Mode — 7/10 (unchanged)

Transport line colors from API cannot be adapted. `Annotation("")` with empty title still present for vehicle annotations (changed from title to empty string in `8763a42` — was `vehicle.line?.displayName ?? "?"`, now `""`). This is an **accessibility regression** introduced in `8763a42`.

**Finding (NEW — regression in 8763a42):**
```swift
// Before (7afccd1):
Annotation(title, coordinate: coordinate)  // title = vehicle.line?.displayName ?? "?"
// After (8763a42):
Annotation("", coordinate: coordinate)  // explicitly empty
```
The vehicle's Annotation title went from meaningful to empty. Map VoiceOver navigation gets worse: navigating the map by swipe now announces nothing for vehicle annotations. The inner `Button` still has `vehicleAccessibilityLabel(for:)` which is correct for tap — but map annotation titles serve a separate role in spatial navigation.

**Auto-decision (P1 — completeness):** Restore the line display name as the Annotation title. The title isn't shown visually in the `LiveVehicleMarkerView` redesign, but it helps VoiceOver.

### Dimension 4–7: unchanged from 2026-03-23.

**Dimension 7 compliance update:**
- `clipShape(.rect(cornerRadius:))` instead of `RoundedRectangle(cornerRadius:)` — still not applied across all views
- Computed view properties — still 9 of them, still violating AGENTS.md

---

## Phase 3: Engineering Review (Updated 2026-04-07)

### Step 0: Scope Challenge

Current file sizes:
- `TransportMapView.swift` — 1471 lines (was 1481; some removal in vehicle marker redesign)
- `VehicleRadarService.swift` — `actor`, well-structured
- `OfflineStopsDatabase.swift` — `actor` now, correct
- `EventsService.swift` — `actor` now, correct
- `CacheService.swift` — `final class @unchecked Sendable`, still wrong annotation

No unnecessary complexity added. macOS Catalyst additions are clean and conditional. Architecture improvements from `8763a42` are substantive.

### Section 1: Architecture (Updated)

```
BerlinTransportMapApp
  └── ContentView
        └── TransportMapView (1471 lines — coordinator + 8 embedded structs)
              │
              ├── @State: 35+ state variables
              │
              ├── ServiceContainer.shared (singleton @MainActor)
              │     ├── TransportService (@MainActor @Observable)
              │     ├── VehicleRadarService (actor ✅)
              │     ├── CacheService (final, @unchecked Sendable ⚠️)
              │     ├── RouteService (@MainActor @Observable ✅)
              │     ├── PredictionService (final ✅)
              │     ├── NetworkMonitor (final @Observable ✅)
              │     ├── EventsService (actor ✅ — NEW)
              │     └── PredictiveLoader (@MainActor @Observable ✅)
              │
              └── OfflineStopsDatabase.shared (actor ✅ — NEW)

SwiftData: Favorite model (no CloudKit, simple)
```

**Architecture improved.** 3 actors now vs 1 before. The two remaining `@unchecked Sendable` users (`CacheService`) are either thread-safe by construction (NSCache) or trivially fixable. The Catalyst macOS commands use `NotificationCenter` for decoupling -- reasonable but slightly fragile (no type safety on the notification name pairing). Could use a `@MainActor` shared observable instead, but the current approach works and scope is small.

### Section 2: Code Quality (Updated)

**Resolved since last review:**
- `Config.apiAuthorization` dead code — removed ✅
- `CacheService.age(of:)` broken method — removed ✅
- `EventsService.shared` dead singleton — removed ✅
- `@unchecked Sendable` on `EventsService` — fixed (now `actor`) ✅
- `@unchecked Sendable` on `OfflineStopsDatabase` — fixed (now `actor`) ✅

**Remaining:**
1. `CacheService: @unchecked Sendable` — NSCache is thread-safe. The only stored properties are `memoryCache` (NSCache) and `cachePrefix` (static). This class can be marked `Sendable` (not `@unchecked`) or better yet `@unchecked` can simply be removed since NSCache's thread safety satisfies Swift's Sendable requirement for classes with no mutable stored instance state beyond NSCache. Add `// NSCache is thread-safe per Apple docs; @unchecked is not needed` or just remove.
2. `HistoricalDataStorage: class` — missing `final`. Violates AGENTS.md convention.
3. `try!` in `BerlinTransportMapApp.swift:24` — acceptable semantically (in-memory cannot fail), but `try!` should be replaced with `do { ... } catch { preconditionFailure("...") }` per Swift best practices (AGENTS.md: "Avoid force unwraps and force try unless it is unrecoverable").
4. `Annotation("", coordinate:)` in `vehicleAnnotation(for:)` — empty title is an accessibility regression vs the previous version that used the line display name.

**`TransportMapView` computed view properties — 9 violating AGENTS.md:**
```
mapContent          → some MapContent
trailOverlay        → some MapContent
stopAnnotations     → some MapContent
vehicleAnnotations  → some MapContent  
routeOverlay        → some MapContent
mainContent         → some View
contentWithSheets   → some View
favoritesSheet      → some View
statusBadge         → some View
```
Plus `vehicleAnnotation(for:)` as a method returning `some MapContent`. Per AGENTS.md: "Do not break views up using computed properties; place them into new `View` structs instead." This is a consistent violation across 9 properties. Each should be a proper struct.

### Section 3: Test Review (Updated)

**Test diagram — current state:**

| Flow / Codepath | Test type | Exists? | Coverage |
|-----------------|-----------|---------|----------|
| `Env.overrideBaseURL` resolution | Unit | ✅ `ConfigTests.swift` | Updated — tests live code now |
| ServiceContainer singleton | Unit | ✅ `ServiceContainerTests.swift` | Smoke test |
| PredictiveLoader start/stop/key | Unit | ✅ | Good |
| Theme color values | Unit | ✅ | Good |
| TransportError types | Unit | ✅ | Good |
| `VehicleRadarService.fetchVehicles` | Unit | ❌ | MISSING |
| `OfflineStopsDatabase.findStops` (bbox) | Unit | ❌ | MISSING — critical math |
| `CacheService.set/get/TTL expiry` | Unit | ❌ | MISSING |
| Vehicle coordinate interpolation math | Unit | ❌ | MISSING — critical for animation |
| SwiftData Favorite CRUD | Unit | ❌ | MISSING |
| Map interaction performance | UI | ✅ | Present |

**Progress:** `ConfigTests` now tests live code instead of dead code (improvement). Core test gaps remain unchanged.

**Critical still-missing tests:**
1. `VehicleMotionPlan.coordinate(at:)` / `projectCoordinate()` — the mathematical heart of smooth vehicle animation. Zero tests.
2. `OfflineStopsDatabase.findStops` bounding-box prefilter — custom geographic math, zero tests.
3. `CacheService` TTL — the cache's core contract not tested.

### Section 4: Performance ✅ (unchanged — still excellent)

No regressions in `8763a42`. Vehicle marker redesign (flat pill instead of circle+arrow) is lighter to render. Stop annotation hide-when-zoomed-out (`return 0`) reduces annotation density at low zoom — positive for performance.

---

### Failure Modes Registry (Updated)

| Failure Mode | Severity | Status |
|-------------|----------|--------|
| `fatalError` on SwiftData store corruption | 🚨 Was High | ✅ Fixed — in-memory fallback |
| `try!` on in-memory ModelContainer | ℹ️ Low | ⚠️ Cosmetic — replace with preconditionFailure |
| Community VBB API goes down | ⚠️ Strategic | ⚠️ Acknowledged, not fixable |
| `CacheService @unchecked Sendable` | ℹ️ Low | ⚠️ Remove annotation |
| `Annotation("")` empty title for vehicles | ⚠️ Medium A11y | ⚠️ NEW REGRESSION in 8763a42 |
| 8 structs + 9 computed props in TMV.swift | ℹ️ Medium | ⚠️ Refactor per AGENTS.md |
| Vehicle interpolation math untested | ⚠️ Medium | ⚠️ Add unit tests |
| Bbox math untested | ⚠️ Medium | ⚠️ Add unit tests |
| `HistoricalDataStorage` not `final` | ℹ️ Low | ⚠️ Add `final` |

---

### Eng Review Completion Summary (Updated)

| Area | Status | Notes |
|------|--------|-------|
| Architecture | ✅ Excellent | 3 actors now; clean macOS Catalyst addition |
| Code quality | ✅ Improved | Major dead code removed; small cleanups remain |
| Test coverage | ⚠️ | Core animation + bbox math still untested |
| Performance | ✅ Excellent | Unchanged; new pill markers cheaper to render |
| Security | ✅ Clean | Dead credential removed |
| Privacy | ✅ Clean | No mismatch |
| Crash risk | ✅ Resolved | `fatalError` → in-memory fallback |
| Concurrency safety | ✅ Mostly | `CacheService @unchecked` is the last holdout |
| Accessibility | ⚠️ Regression | `Annotation("")` empty title is worse than `7afccd1` |

---

## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|-----------|-----------|----------|----------|
| 1 | CEO | Community API risk = strategic risk, not blocker | Mechanical | P3 | Can't fix without VBB cooperation | Block launch |
| 2 | CEO | `try!` on in-memory = low priority cosmetic fix | Mechanical | P5 | Truly cannot fail; still ugly | Accept `try!` forever |
| 3 | CEO | SELECTIVE EXPANSION mode | Mechanical | P3 | Live app, solo dev — fix correctness | SCOPE_EXPANSION |
| 4 | CEO | 8 embedded structs = fix (mechanical per AGENTS.md) | Mechanical | P5 | Clearly correct per AGENTS; blast radius = 1 file | Ignore |
| 5 | CEO | 9 computed view props = fix (per AGENTS.md) | Mechanical | P5 | Same as above | Ignore |
| 6 | Design | `Annotation("")` regression = fix | Mechanical | P1 | Accessibility regression vs prior version | Keep empty |
| 7 | Design | `CacheService @unchecked Sendable` = remove annotation | Mechanical | P5 | NSCache thread-safe; annotation misleads | Keep @unchecked |
| 8 | Eng | Vehicle interp math + bbox = add tests | Mechanical | P2 | Critical math in blast radius; no tests = silent regression risk | Defer |
| 9 | Eng | `HistoricalDataStorage` add `final` | Mechanical | P5 | AGENTS.md; 1-word fix | Ignore |

---

## Phase 4: Final Approval Gate

### /autoplan Review Complete

**Plan Summary:** Live iOS + macOS Catalyst transit map app. Commit `8763a42` resolved all high-priority findings from the 2026-03-23 review. What remains is a set of low-to-medium mechanical cleanups: file organization, computed-property-to-struct extraction, one accessibility regression, and missing unit tests for core math.

**Decisions Made: 9 total (9 auto-decided, 0 taste choices, 0 user challenges)**

### Auto-Decided: 9 decisions (see Decision Audit Trail above)

### Review Scores
- **CEO:** Strong. API dependency risk acknowledged. All structural premises now valid.
- **CEO Voices:** Single-reviewer mode (Codex unavailable). Subagent: 2 findings (try!, macOS Catalyst coupling via NotificationCenter).
- **Design:** 3 issues open. One new accessibility regression in 8763a42 (`Annotation("")`). Theme token wiring and ClipShape modernization unchanged.
- **Eng:** Architecture excellent. 3 actors. Test coverage gaps in critical math remain.
- **DX:** Skipped — end-user iOS app.

### Cross-Phase Themes
**Theme: `TransportMapView.swift` organization** — flagged in Phase 1 (scope risk), Phase 2 (computed props), Phase 3 (embedded structs). High-confidence signal. This file should be the top target for the next commit.

### Deferred to TODOS
- Widget extension
- Apple Watch companion
- Official API migration
- Events UI surface improvement

---

## Action List (Priority Order)

1. **[A11y regression — fix first]** `vehicleAnnotation(for:)` in `TransportMapView.swift`: restore the line name as `Annotation` title:
   ```swift
   Annotation(vehicle.line?.displayName ?? "", coordinate: coordinate)
   ```
2. **[Mechanical]** `TransportMapView.swift`: extract 8 embedded structs to own files, convert 9 computed view properties to proper `View` structs.
3. **[Mechanical]** `CacheService.swift`: remove `@unchecked Sendable` — NSCache is already thread-safe.
4. **[Mechanical]** `HistoricalData.swift`: add `final` to `HistoricalDataStorage`.
5. **[Mechanical]** `BerlinTransportMapApp.swift:24`: replace `try!` with `do-catch { preconditionFailure("...") }`.
6. **[Tests]** Add unit tests for `VehicleMotionPlan.coordinate(at:)`, `OfflineStopsDatabase.findStops` bounding-box, `CacheService` TTL expiry.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 2 | ✅ Complete | 8763a42 resolved high-priority issues; 2 low items remain |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — unavailable | — |
| Eng Review | `/plan-eng-review` | Architecture & tests | 2 | ✅ Complete | Architecture excellent; test gaps + 1 a11y regression |
| Design Review | `/plan-design-review` | UI/UX gaps | 2 | ✅ Complete | 1 regression (Annotation title), 2 open cosmetic issues |

**VERDICT:** APPROVED — No blocking issues. 1 accessibility regression to fix before next release. 5 mechanical cleanups. All critical bugs from prior review resolved.
