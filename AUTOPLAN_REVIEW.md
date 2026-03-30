<!-- /autoplan restore point: /Users/rd/.gstack/projects/berlin-realtime-map/main-autoplan-restore-20260323.md -->

# Berlin Transport Map — /autoplan Full Review

**Branch:** main | **Commit:** 7afccd1 | **Date:** 2026-03-23 | **REPO_MODE:** solo

---

## Here's what I'm working with

Berlin Transport Map is a **live iOS app** (App ID 6757723208) showing real-time VBB vehicle positions on a MapKit map. Free with tip jar. Stack: Swift 6, SwiftUI, SwiftData, MapKit, VBB REST API `v6.vbb.transport.rest`. Architecture: single `TransportMapView` (1481 lines) as the coordinator, backed by a `ServiceContainer` singleton with 8 services. **UI scope: YES** — map-heavy with custom annotations, sheets, and status overlays.

---

## Phase 1: CEO Review — Strategy & Scope

### Step 0A: Premise Challenge

| Premise | Status | Verdict |
|---------|--------|---------|
| "Real-time vehicle positions" | ✅ True | `VehicleRadarService` polls `v6.vbb.transport.rest/radar` every 15–30s |
| "No account, no tracking" | ✅ True | No auth, no analytics SDK; `PrivacyInfo.xcprivacy` exists |
| "Full VBB network" | ✅ True | Offline stops database covers Berlin Brandenburg |
| "No third-party SDK" | ✅ True (no TripKit despite marketing doc mention) | All API calls are direct REST. No third-party packages in the project. |
| "VBB API will remain stable and free" | ⚠️ RISK | `v6.vbb.transport.rest` is community-hosted by @derhuerst — not an official VBB API. Unofficial free tier. Rate limits and availability are not guaranteed. |
| "Privacy first — location is optional" | ✅ Mostly true | `LocationManager` requests only when-in-use; map works without location |
| "German/French localization" | ⚠️ PARTIAL | `de.lproj` exists but most UI strings in views are hardcoded English |
| "Config.apiAuthorization (VBB_API_AID) is used" | ❌ DEAD CODE | `Config.apiAuthorization` is defined and tested but **never called** anywhere in the network layer. The AID is hardcoded defensively but silently unused. |

**Auto-decision (P4 — DRY):** `Config.apiAuthorization` is dead code. Flag for removal.

**GATE [premises needing human confirmation]:** The VBB API dependency is the existential risk. `v6.vbb.transport.rest` is a community project, not VBB's official API. If it goes down or rate-limits the app, all core functionality breaks. Human must acknowledge this risk before proceeding to production decisions.

---

### Step 0B: Existing Code Leverage Map

| Sub-problem | Where it lives today |
|-------------|---------------------|
| Real-time vehicle positions | `VehicleRadarService` (actor) — polls `/radar` |
| Stop search + nearby | `TransportService` + `OfflineStopsDatabase` |
| Departures | `VehicleRadarService.fetchDepartures()` + `TransportService.queryDepartures()` |
| Route overlay | `RouteService` |
| Offline stop database | `OfflineStopsDatabase` — bundles JSON, 7-day cache TTL |
| In-memory caching | `CacheService` (NSCache + TTL) |
| Predictive prefetch | `PredictiveLoader` + `UserPatternService` |
| Prediction persistence | `PredictionService` + `HistoricalData` → JSON in AppSupport |
| Events | `EventsService` (fetches from `api.berlin.de/events/`) |
| Favorites | `FavoritesService` + SwiftData `Favorite` model |
| Map tile warmup | `MapTilePreloader` in `BerlinTransportMapApp` |

---

### Step 0C: Dream State Diagram

```
CURRENT STATE (7afccd1)               THIS PLAN            12-MONTH IDEAL
───────────────────────────────  ─────────────────────  ──────────────────────────────
• Live on App Store                Fix dead code,        • Lock-screen widget (WidgetKit)
• Community VBB API (risk)         fix localization,     • Official VBB API (if available)
• 1481-line TransportMapView       fix @unchecked        • Siri integration / shortcuts
• Dead code (Config.apiAid)        Sendable pattern      • Apple Watch companion
• Hardcoded AID in source          violations            • Departure board in standby mode
• Inconsistent localization                              • Search from Spotlight
• @unchecked Sendable on 5 services
• No unit tests for network services
• Events feature barely connected to UI
• Excellent map performance ✅
• Smooth vehicle animation ✅
```

### Step 0C-bis: Implementation Alternatives

| Initiative | Effort (human) | Effort (CC) | Risk |
|------------|---------------|-------------|------|
| A) Fix SwiftUI pattern violations + dead code | 2 days | 30 min | Low |
| B) Add real localization (DE/FR strings) | 3 days | 1 hour | Low |
| C) Proper Sendable conformance (remove @unchecked) | 1 day | 2 hours | Medium |
| D) Widget extension for nearby stops | 1 week | 3 hours | Medium |
| E) Official API migration (when/if available) | Unknown | Unknown | High |

---

### Step 0D: Mode — SELECTIVE EXPANSION

Hold scope: focus on correctness, code quality, and pattern compliance. Apple is live, so shipping stability > new features.

**In scope (pre-next-update):**
1. Remove dead `Config.apiAuthorization` / `Env.apiAid` code (or wire it up properly)
2. Fix `@unchecked Sendable` on 5 service classes — they suppress concurrency safety
3. Fix `fatalError` in `BerlinTransportMapApp` for `ModelContainer` failure
4. `stopAnnotations` + `vehicleAnnotations` + `mainContent` + `contentWithSheets` + `favoritesSheet` + `statusBadge` — 6 computed-property sub-views in `TransportMapView`; should be proper View structs per AGENTS.md
5. Localization: most UI strings are hardcoded English despite `de.lproj` existing
6. `CacheService.age(of:)` returns `nil` unconditionally — broken implementation

**Deferred to TODOS.md:**
- Widget extension
- Apple Watch
- Events UI integration
- Official API migration

---

### Step 0E: Temporal Interrogation

**HOUR 1 — First crash path:**
`BerlinTransportMapApp.swift` line 19: `fatalError("Could not create ModelContainer: \(error)")`. A corrupted SwiftData store on an over-the-air update would crash the app on every launch with no recovery path. Should fail gracefully with in-memory fallback or store migration.

**HOUR 6 — API failure cascade:**
If `v6.vbb.transport.rest` is rate-limited or down, `TransportService` throws `TransportError.networkError("Invalid response")` → alert shown. The offline stops database provides graceful degradation for stop search, but vehicle positions go blank. The `stale` data source state is shown correctly via the status badge — good UX.

**DAY 1 — Concurrency:**
`OfflineStopsDatabase` is `@unchecked Sendable` with mutable `allStops: [TransportStop]` array. It's accessed from `TransportService` (called from `TransportMapView` which is `@MainActor`), but `loadIfNeeded()` is called from the app `init()` on a background `Task`. If both paths hit `loadIfNeeded()` simultaneously, mutable state is not protected. No crash observed in testing, but the thread safety guarantee is not enforced by the type system.

---

### Step 0F: Mode Confirmation

SELECTIVE EXPANSION. Fix structural issues in the blast radius. Ship existing functionality cleanly.

---

### Section 1: Problem–Solution Fit ✅

Real-time transit positions is an underserved niche in Berlin transit apps. The BVG official apps don't show live vehicle map positions. This is a genuine gap the app fills well. The MapKit approach with smooth vehicle animation is technically superior to most alternatives. **Rating: Strong.**

---

### Section 2: Error & Rescue Registry

| Error Scenario | Where | Current handling | Gap |
|----------------|-------|-----------------|-----|
| VBB REST API down | All services | `TransportError.networkError` → alert | Alert text is technical ("HTTP 503") — no user-friendly guidance |
| SwiftData store corruption on launch | `BerlinTransportMapApp` | `fatalError` | 🚨 CRASH with no recovery — must add graceful fallback |
| Offline stops DB fails to load from bundle | `OfflineStopsDatabase.loadFromBundle()` | Returns `false` → tries network download | Good |
| Location permission denied | `LocationManager` | Graceful — map works without GPS | Good |
| Events API unavailable | `EventsService` | `EventsError.networkError` thrown | Silently dropped in UI — events feature barely shows up to user anyway |
| VehicleRadarService decode failure | `vehicleDecoder.decode` | Throws, vehicle load fails | No logging to help debug in production |

---

### Section 3: Distribution & Growth ✅

- ASO is well-optimized: title has keyword, subtitle is excellent, keyword field at 84/100 chars.
- `requestReview()` fires after each vehicle data fetch count increment — reasonable trigger.
- No share-from-app flow, but the nature of a transit map makes sharing less natural than GoToAppleMaps.

---

### Section 4: Monetization ✅

Tip jar with StoreKit is well-implemented. Appropriate for a utility app.

---

### Section 5: Platform Leverage ✅

- SwiftData for `Favorite` persistence — modern, correct approach.
- `MapTilePreloader` warms up tiles on launch — smart perf optimization.
- Adaptive polling: 15s when user is moving, 30s otherwise — smart.
- `VehicleRadarService` as a Swift `actor` — correct isolation for concurrent fetch.
- `@MapContentBuilder` — modern MapKit DSL used correctly.

---

### Section 6: Scope Risks ⚠️

- `TransportMapView.swift` at 1481 lines with nested structs inside (`LiveVehicleMarkerView`, `StopMarkerView`, `RESTDeparturesSheet`, `RESTDepartureRow`, `VehicleInfoSheet`, `DeveloperInfoSheet`, `EventDetailsSheet`) — these should each be their own file per AGENTS.md ("Break different types up into different Swift files").
- 50% of `TransportMapView`'s complexity is the view itself; 50% is the 8 embedded structs that should live elsewhere.

---

### Section 7: Technical Debt ⚠️

**`Config.apiAuthorization` — dead code, creates false security impression:**
`Config.swift` defines an AID credential + env-var override. `ConfigTests.swift` tests it. But `Config.apiAuthorization` is never called in any service. The VBB REST v6 API doesn't require an AID for public endpoints. This creates confusion: tests pass, credential appears wired, it's never actually sent to the API.

**`CacheService.age(of:)` — broken implementation:**
```swift
func age(of key: String) -> TimeInterval? {
    guard let entry = memoryCache.object(forKey: key as NSString) else { return nil }
    let remaining = entry.expiresAt.timeIntervalSinceNow
    return remaining < 0 ? nil : nil // Both branches return nil
}
```
This always returns `nil`. If anything calls this expecting an age, it gets nothing. Dead or broken implementation.

**`@unchecked Sendable` on 5 classes** — suppresses Swift's concurrency checker for the entire service layer:
- `CacheService` — mutable `NSCache` (thread-safe, but the `@unchecked` marks the whole class)
- `TransportService` — mutable `session`, `decoder` — these are actually immutable after init; this could be `Sendable` properly
- `EventsService` — mutable `cachedEvents` + `cacheTimestamp` — not thread-safe
- `OfflineStopsDatabase` — mutable `allStops`, `isLoaded` — not thread-safe
- `RouteService` — likely immutable; could be proper `Sendable`

**`HistoricalDataStorage` — missing `final`:**
`class HistoricalDataStorage` without `final` — doesn't conform to AGENTS.md pattern.

---

### Section 8: Security ⚠️ Low risk, one cleanup needed

**`Config.swift` hardcoded AID `"1Rxs112shyHLatUX4fofnmdxK"`:**
This is a VBB API AID (authorization ID). However:
1. The VBB REST v6 API does NOT require authentication for public endpoints (the AID is for the legacy HAFAS API, which is different).
2. `Config.apiAuthorization` is never actually sent in any request — it's dead code.
3. Even if sent, the AID is a legacy open/deprecated credential, not a private key.

**Risk level: Low** — this is not a live credential leak like the GoToAppleMaps JWT. The AID is unused and the VBB API doesn't require it. However, dead-credential code in source is still worth cleaning up.

**No SSRF, injection, or XSS vectors found.** All URLs are constructed with `URLComponents` + `URLQueryItem` which escapes parameters. No user-supplied strings are inserted directly into URLs.

---

### Section 9: Privacy & Compliance ✅

- Location: `NSLocationWhenInUseUsageDescription` must be in Info.plist — standard.
- `PrivacyInfo.xcprivacy` exists.
- No third-party analytics.
- Events API fetches from `api.berlin.de` — public data, no PII sent.
- VBB API: queries include lat/lon when fetching nearby stops, but this is no different from any maps app querying for local content.

The privacy story is clean and honest. No mismatch (unlike GoToAppleMaps).

---

### Section 10: NOT In Scope

- Official VBB API migration
- WidgetKit extension
- Apple Watch companion
- Siri shortcuts
- Departure board for StandBy mode
- Multi-city support

---

### What Already Exists (sub-problem → code quality)

| Sub-problem | Code | Quality |
|-------------|------|---------|
| Vehicle polling + projection | `VehicleRadarService` (actor) | ✅ Excellent |
| Tile warmup | `MapTilePreloader` | ✅ Smart |
| Offline stops DB | `OfflineStopsDatabase` | ✅ Good (bounding-box prefilter) |
| NSCache caching | `CacheService` | ⚠️ `age()` broken |
| Predictive loading | `PredictiveLoader` | ✅ Well structured |
| Historical prediction | `PredictionService` + `HistoricalData` | ⚠️ Very lightly used |
| Events | `EventsService` | ⚠️ Fetches data but barely surfaces in UI |
| Config/credentials | `Config.swift` + `Env.swift` | ❌ Dead code |

---

### CEO Review Completion Summary

| Area | Status | Critical Issues |
|------|--------|----------------|
| Problem-solution fit | ✅ Strong | — |
| Error handling | ⚠️ | `fatalError` on ModelContainer failure is a crash risk |
| Distribution/ASO | ✅ Good | Already optimized |
| Monetization | ✅ Good | — |
| Platform leverage | ✅ Excellent | MapKit, SwiftData, actor, adaptive polling |
| Scope risks | ⚠️ | 7 structs embedded in one giant file |
| Technical debt | ⚠️ | Dead Config code, broken `age()`, `@unchecked Sendable` |
| Security | ⚠️ Low | Hardcoded but unused AID, low risk |
| Privacy | ✅ Clean | — |
| API dependency risk | ⚠️ Strategic | Community VBB API, no SLA |

---

## Decision Audit Trail

| # | Phase | Decision | Principle | Rationale | Rejected |
|---|-------|----------|-----------|-----------|----------|
| 1 | CEO | Community API risk = strategic risk, not blocker | P3 (pragmatic) | Can't fix without VBB cooperation; flag and proceed | Block launch |
| 2 | CEO | Dead Config code = fix (mechanical) | P4 (DRY) | Zero value, misleads readers and tests | Keep |
| 3 | CEO | fatalError on ModelContainer = fix | P1 (completeness) | Crash with no recovery is a ship blocker | Accept crash |
| 4 | CEO | @unchecked Sendable = TASTE (fix complexity varies) | P3 (pragmatic) | Some easy (RouteService), some hard (OfflineStopsDatabase) | Auto-fix all |
| 5 | CEO | SELECTIVE EXPANSION mode | P3 (pragmatic) | Live app, solo dev — fix correctness, don't add features | SCOPE_EXPANSION |
| 6 | CEO | 7 embedded structs in TransportMapView.swift = TASTE | P5 (explicit) | Large mechanical refactor; clearly correct per AGENTS.md | Ignore |
| 7 | CEO | Localization gaps = flag, not auto-fix | P6 (bias toward action) | Human must write translations; code is straightforward | Auto-fix |

---

## Phase 2: Design Review

### Dimension 1: Visual Hierarchy — 8/10

`Theme.swift` defines `TransportTheme` with semantic colors (`haltestelleYellow`, `haltestelleGreen`, status colors). However, **most views in `TransportMapView.swift` don't use the theme tokens** — they use inline `Color.red.opacity(0.9)`, `Color.orange.opacity(0.9)`, `Color.green.opacity(0.9)` which duplicate `TransportTheme.Status.live/.cached/.offline`. The theme exists but isn't consistently applied.

**Finding:** `cacheBadgeColor` in `TransportMapView` duplicates `TransportTheme.Status` values:
```swift
// In TransportMapView:
Color.red.opacity(0.9)      // = TransportTheme.Status.offline ✓ same value, different reference
Color.orange.opacity(0.9)   // = TransportTheme.Status.cached ✓ same
Color.green.opacity(0.9)    // = TransportTheme.Status.live ✓ same
```
Not a visual bug, but a maintainability issue — a single source of truth exists but isn't used.

**Auto-decision (P5 — explicit):** Flag for wiring up. Mechanical fix, blast radius: `TransportMapView.swift` only.

### Dimension 2: Spacing & Layout — 7/10

No spacing/padding design system (no equivalent of GoToAppleMaps's `DesignTokens.spacing*`). Values are hardcoded throughout: `.padding(8)`, `.padding(12)`, `.frame(width: 44)`, `.frame(height: 44)` etc. The UI looks good but spacing isn't token-driven, which makes future maintenance harder.

**Not a blocking issue** — the visual result is good. Flagging as improvement opportunity.

### Dimension 3: Color & Dark Mode — 7/10

`TransportTheme` provides semantic status colors which are defined as `Color` literals without dark mode adaptation. `Color.green.opacity(0.9)` looks the same in light and dark mode — which is reasonable for status indicators. Transport line colors come from the API (`Color(hex: vehicle.line?.color)`) — cannot be adapted.

**One issue:** `stopAnnotations` in map content: `Annotation("", coordinate:)` uses an empty string for the title. This means VoiceOver gets no coordinate context. The button inside sets `accessibilityLabel(stop.name)` which is correct, but the empty Annotation title is a gap.

### Dimension 4: Typography — 7/10

No type scale defined. Fonts are set ad-hoc with `.font(.caption)`, `.font(.system(size: 11))`, `.font(.headline)`. The `Theme.swift` has no typography section. Visual result is consistent-enough but there's no enforced scale.

**Auto-decision (P3 — pragmatic):** Don't add a new typography system now. Flag for follow-up.

### Dimension 5: Animation & Motion — 9/10

Vehicle interpolation/projection logic in `TransportMapView` is excellent. `withAnimation` wraps vehicle position updates. `@Environment(\.accessibilityReduceMotion)` is used. Adaptive polling adjusts based on user activity. The trail overlay animates smoothly. This is the standout feature of the app and it's polished.

### Dimension 6: Accessibility — 7/10

**Issues found:**
- `stopAnnotations`: `Annotation("")` — empty title creates poor VoiceOver map navigation. The accessibility label on the inner button is correct; the Annotation title should also be set.
- `vehicleAnnotation`: Uses `vehicleAccessibilityLabel(for:)` — good, meaningful labels.
- `StopAnnotationView.swift`: Uses `RoundedRectangle(cornerRadius: 4)` — should use `.rect(cornerRadius: 4)` clipShape per copilot-instructions preference, though older API form works.
- Color-only status indicators (red/orange/green badge) — no text description for colorblind users beyond the icon name.
- The status badge chip (`"wifi"`, `"wifi.slash"`, `"clock.arrow.circlepath"`) includes a text label ("Live", "Offline", "Stale") — good.

### Dimension 7: AGENTS.md / Copilot Instructions Compliance — 6/10

Checking [copilot-instructions.md](../.github/copilot-instructions.md) rules:

| Rule | Status |
|------|--------|
| `foregroundStyle()` not `foregroundColor()` | ✅ (`foregroundColor` not found in Swift files) |
| `clipShape(.rect(cornerRadius:))` not `cornerRadius()` | ⚠️ `RoundedRectangle(cornerRadius:)` used in many places; not `.rect(cornerRadius:)` shorthand |
| `Tab` API not `tabItem()` | N/A — no TabView |
| `@Observable` not `ObservableObject` | ✅ |
| `onChange()` 2-parameter variant | ✅ (confirmed in grep) |
| No `onTapGesture()` | ✅ — `Button` used throughout |
| `Task.sleep(for:)` not `nanoseconds:` | ✅ |
| No broken views into computed properties | ❌ **VIOLATION**: 6 computed properties in `TransportMapView` return `some View`/`some MapContent` |
| `NavigationStack` not `NavigationView` | ✅ |
| `Button` with text + image | ✅ where applicable |
| `bold()` not `fontWeight(.bold)` | ✅ where found |
| No `GeometryReader` where avoidable | ✅ |
| Break types into separate Swift files | ❌ **VIOLATION**: 7 View structs inside `TransportMapView.swift` |
| `final` on all classes | ❌ `HistoricalDataStorage` missing `final` |

---

## Phase 3: Engineering Review

### Step 0: Scope Challenge

Read code: `TransportMapView.swift` (1481 lines), `VehicleRadarService.swift` (386 lines), `OfflineStopsDatabase.swift` (345 lines), `CacheService.swift` (120 lines), `ServiceContainer.swift` (32 lines), `Config.swift` (16 lines).

No unnecessary complexity found. Services are well-bounded. The main structural issues are the file-organization violations and the `@unchecked Sendable` suppressions.

### Step 0.5: Codex — Unavailable. Single-reviewer mode.

### Section 1: Architecture

```
BerlinTransportMapApp
  └── ContentView (thin wrapper, 56 lines)
        └── TransportMapView (1481 lines — coordinator + 7 embedded structs)
              │
              ├── @State: 35+ state variables
              │
              ├── ServiceContainer.shared (singleton @MainActor)
              │     ├── TransportService (@MainActor @Observable, @unchecked Sendable)
              │     ├── VehicleRadarService (actor ✅)
              │     ├── CacheService (final, @unchecked Sendable)
              │     ├── RouteService (@unchecked Sendable)
              │     ├── PredictionService (final)
              │     ├── NetworkMonitor (final, @Observable)
              │     ├── EventsService (@unchecked Sendable)
              │     └── PredictiveLoader (@MainActor @Observable)
              │
              └── OfflineStopsDatabase.shared (singleton, @unchecked Sendable)

SwiftData: Favorite model (simple, no CloudKit)
```

**Architecture is sound.** The `actor` for `VehicleRadarService` is the correct choice for the one service that does most of the concurrent work. The singleton `ServiceContainer` is appropriate for an app this small.

**Coupling issue:** `TransportMapView` has 35+ `@State` variables — it manages both the view state AND the service orchestration. Ideally a `@Observable` ViewModel would hold the service orchestration state, but for a solo project this is acceptable and refactoring it would be a large change. Flagging as improvement, not blocking.

### Section 2: Code Quality

**Dead code found:**
1. `Config.apiAuthorization` + `Env.apiAid` — defined, tested, never called. The AID is NOT sent in any HTTP request.
2. `CacheService.age(of:)` — always returns `nil` regardless of input.
3. `EventsService` + `EventsService.shared` — `EventsService` has both a `shared` singleton AND is instantiated fresh in `ServiceContainer`. The two instances are separate objects. The `shared` is never referenced by the service container or TransportMapView. Dead singleton.

**`@unchecked Sendable` audit:**
- `RouteService` — only has `let baseURL: String` and a `URLSession`. Likely thread-safe, `@unchecked` is conservative but removing it requires verification. Low risk.
- `TransportService` — `@MainActor @Observable` + `@unchecked Sendable` is contradictory. `@MainActor` types are already `Sendable`. The `@unchecked` is redundant and confusing.
- `CacheService` — uses `NSCache` which is thread-safe. The `@unchecked` is technically accurate but `NSCache` already provides synchronization.
- `EventsService` — has mutable `cachedEvents` and `cacheTimestamp` without a lock. Genuinely not thread-safe. `@unchecked` is suppressing a real issue.
- `OfflineStopsDatabase` — mutable `allStops` and `isLoaded` without protection. Same as above.

**`fatalError` in app init:**
```swift
} catch {
    fatalError("Could not create ModelContainer: \(error)")
}
```
If a SwiftData migration fails on app update, the user gets a crash loop with no way out. The correct pattern is to fall back to an in-memory container.

### Section 3: Test Review

**Test diagram — codepaths and coverage:**

| Flow / Codepath | Test type | Exists? | Coverage |
|-----------------|-----------|---------|----------|
| Config AID resolution (env var / fallback) | Unit | ✅ `ConfigTests.swift` | Good (tests dead code though) |
| ServiceContainer singleton + services not nil | Unit | ✅ `ServiceContainerTests.swift` | Smoke test only |
| PredictiveLoader start/stop/key | Unit | ✅ `PredictiveLoaderTests.swift` | Good |
| Theme color values | Unit | ✅ `ThemeTests.swift` | Good |
| TransportError types | Unit | ✅ `TransportErrorTests.swift` | Good |
| VehicleRadarService.fetchVehicles | Unit | ❌ | MISSING |
| TransportService.queryNearbyStops | Unit | ❌ | MISSING |
| OfflineStopsDatabase.searchStops | Unit | ❌ | MISSING |
| OfflineStopsDatabase.findStops (bounding box) | Unit | ❌ | MISSING |
| CacheService.set/get/TTL expiry | Unit | ❌ | MISSING |
| RouteService | Unit | ❌ | MISSING |
| Vehicle interpolation math | Unit | ❌ | MISSING |
| SwiftData Favorite CRUD | Unit | ❌ | MISSING |
| UI screenshot flow | UI | ✅ `ScreenshotUITests.swift` | Present |
| Map interaction performance | UI | ✅ (untracked file) | Present |

**Critical test gaps:**
1. `OfflineStopsDatabase.searchStops` — the bounding-box prefilter is a performance-critical path with custom math. Not tested.
2. `CacheService` TTL expiry — the cache's core contract (items expire after TTL) is not tested.
3. Vehicle interpolation/projection math — `VehicleMotionPlan.coordinate(at:)` and `projectCoordinate()` are the heart of the smooth animation feature and have zero tests.
4. `ConfigTests` tests dead code — confirms behavior of code that's never executed. Tests pass but prove nothing about app behavior.

**Auto-decision (P2 — boil lakes):** Vehicle interpolation math and OfflineStopsDatabase are in the blast radius of any map perf work. Add tests for these. CacheService TTL test is a lake, not an ocean.

### Section 4: Performance ✅

- Bounding-box prefilter in `OfflineStopsDatabase.findStops` — excellent, avoids trig for out-of-range stops.
- Stop render limit scales with zoom level (`stopAnnotationLimit`) — correct.
- Vehicle render limit scales with zoom — correct.
- `vehicleRenderedPositions` dictionary updated via `withAnimation` — smooth.
- Polling adapts: 15s when recently moved, 30s otherwise — thoughtful.
- `MapTilePreloader` on launch — preemptive tile caching is a nice UX touch.

No performance issues found.

---

### Failure Modes Registry

| Failure Mode | Severity | Detected? | Recovery |
|-------------|----------|-----------|----------|
| `fatalError` on SwiftData store corruption | 🚨 High | ✅ | Add in-memory fallback container |
| Community VBB API goes down | 🚨 Strategic | ✅ | Offline stops + stale badge — graceful |
| `@unchecked Sendable` on EventsService | ⚠️ Medium | ✅ | Data race possible on cachedEvents |
| `@unchecked Sendable` on OfflineStopsDatabase | ⚠️ Medium | ✅ | Data race on allStops during load |
| Dead Config/Env code | ⚠️ Low | ✅ | Remove dead code |
| `CacheService.age()` always nil | ⚠️ Low | ✅ | Fix or remove |
| 7 structs in one file | ℹ️ Low | ✅ | Refactor per AGENTS.md |
| Vehicle interpolation math untested | ⚠️ Medium | ✅ | Add unit tests |
| Bounding box math untested | ⚠️ Medium | ✅ | Add unit tests |
| EventsService.shared vs container instance | ℹ️ Low | ✅ | Remove unused singleton |

---

### Eng Review Completion Summary

| Area | Status | Notes |
|------|--------|-------|
| Architecture | ✅ Clean | `actor` for VehicleRadar, SwiftData for Favorites |
| Code quality | ⚠️ | Dead code (Config, CacheService.age, EventsService.shared) |
| Test coverage | ⚠️ | Core math (interpolation, bbox) untested; good unit scaffolding exists |
| Performance | ✅ Excellent | Adaptive polling, bbox filter, tile warmup, render limits |
| Security | ✅ | No live credential leak; unused AID is low-risk |
| Privacy | ✅ | Clean story, no mismatch |
| `fatalError` crash risk | ⚠️ High | ModelContainer corrupt → infinite crash loop |
| Concurrency safety | ⚠️ | `@unchecked Sendable` suppresses real races in 2 services |

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | ✅ Complete | Strategic API risk, dead code |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — unavailable | — |
| Eng Review | `/plan-eng-review` | Architecture & tests | 1 | ✅ Complete | 6 findings |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | ✅ Complete | 3 findings |

**VERDICT:** REVIEWED — No blocking launch issues. 1 high-priority fix (fatalError), 3 medium-priority cleanups.
