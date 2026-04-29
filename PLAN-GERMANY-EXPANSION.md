<!-- /autoplan restore point: /Users/rd/.gstack/projects/dautovri-berlin-realtime-map/feat-germany-expansion-autoplan-restore-20260429-090331.md -->
# German Transit Map — Expansion Plan

## Goal
Transform "Berlin Transport Map" into "German Transit Map" covering all major cities,
using the Deutsche Bahn transport.rest API (`v6.db.transport.rest`).

## Why One App, Not Ten
Apple Guideline 4.3 (Spam) bans template apps. One unified app with city auto-detection
is both safer and strategically better (consolidated reviews, download velocity, ASO).

## Architecture Changes Required

### Phase 1: City Configuration System
**Status:** Not started
**Effort:** ~2 days

Create a `CityConfig` model that encapsulates all city-specific data:

```swift
struct CityConfig: Identifiable, Codable {
    let id: String              // "berlin", "munich", "hamburg"
    let name: String            // "Berlin", "München", "Hamburg"
    let transitAuthority: String // "BVG", "MVG", "HVV"
    let apiBaseURL: String      // "https://v6.vbb.transport.rest" or "https://v6.db.transport.rest"
    let centerCoordinate: CLLocationCoordinate2D
    let defaultZoom: Double
    let boundingBox: MKCoordinateRegion
    let accentColor: Color      // City-specific brand color
    let supportedProducts: [TransportProduct]  // S-Bahn, U-Bahn, tram, bus, ferry
}
```

Pre-configured cities (all use `v6.db.transport.rest` except Berlin which uses `v6.vbb.transport.rest`):

| City | Transit Auth | API | Population | Priority |
|------|-------------|-----|-----------|----------|
| Berlin | BVG/VBB | v6.vbb.transport.rest | 3.8M | Already live |
| Munich | MVG | v6.db.transport.rest | 1.5M | P1 |
| Hamburg | HVV | v6.db.transport.rest | 1.9M | P1 |
| Frankfurt | RMV | v6.db.transport.rest | 750K | P2 |
| Cologne | KVB | v6.db.transport.rest | 1.1M | P2 |
| Stuttgart | VVS | v6.db.transport.rest | 635K | P3 |
| Düsseldorf | VRR | v6.db.transport.rest | 620K | P3 |
| Dresden | DVB | v6.db.transport.rest | 560K | P3 |
| Leipzig | LVB | v6.db.transport.rest | 600K | P3 |
| Nürnberg | VAG | v6.db.transport.rest | 520K | P3 |

### Phase 2: Refactor Berlin-Specific Code
**Status:** Not started
**Effort:** ~3 days

Files with Berlin-specific references that need refactoring:

1. **Config.swift** — Replace `VBB_BASE_URL` with `CityConfig.apiBaseURL`
2. **TransportModels.swift** — Rename VBB-prefixed types to generic names:
   - `VBBSimpleLocation` → `TransitLocation`
   - `VBBDeparture` → `RESTDeparture` (already exists partially)
   - `vbbStopId` → `stopId`
3. **TransportService.swift** — Accept `CityConfig` for API base URL
4. **VehicleRadarService.swift** — Accept `CityConfig` for endpoint
5. **OfflineStopsDatabase.swift** — Load stops per city (not just Berlin)
6. **TransportMapView.swift** — Default region from `CityConfig`
7. **OnboardingView.swift** — Show city-specific preview stops
8. **Theme.swift** — Support city accent colors
9. **FavoriteRow.swift** — Remove Berlin-specific assumptions
10. **PredictiveLoader.swift** — Generalize for any city

### Phase 3: City Picker UI
**Status:** Not started
**Effort:** ~1 day

- First launch: auto-detect via `CLLocationManager`
- If outside Germany: show city picker
- Settings → Change City
- Each city shows its transit authority logo + color accent

### Phase 4: Offline Stops Database Per City
**Status:** Not started
**Effort:** ~2 days

- Fetch and cache stops for each city from the API
- Bundle top-50 stops per city for instant first-launch experience
- Download full stop list in background on first city selection

### Phase 5: App Store Transition
**Status:** Not started
**Effort:** ~1 day

1. **Rename app** in ASC: "German Transit Map: Live Departures"
2. **Update subtitle**: "S-Bahn, U-Bahn, Tram & Bus — All Cities"
3. **New keywords**: BVG, MVG, HVV, RMV, KVB, VVS, S-Bahn, U-Bahn, Abfahrten
4. **Create Custom Product Pages** (CPPs) for Munich, Hamburg, Frankfurt
5. **New screenshots** showing multiple cities
6. **Update description** to list all supported cities

### Phase 6: Freemium Monetization
**Status:** Not started
**Effort:** ~2 days

Free tier:
- Live map + departures for all cities
- 2 favorite stops

Pro tier ($0.99/mo or $9.99/yr or $14.99 lifetime):
- Live Activities / Dynamic Island countdown
- Unlimited favorite stops
- Home screen widgets
- City-themed alternate app icons
- Ad-free experience

Use RevenueCat for paywall management.

## Execution Order

| Week | Task | Deliverable |
|------|------|-------------|
| 1 | Phase 1 + 2 | CityConfig system, refactored services |
| 2 | Phase 3 + 4 | City picker UI, offline stops |
| 3 | Phase 5 + 6 | ASC update, freemium paywall |
| 4 | Testing + Ship | Submit v2.0 to App Store |

## Revenue Projection
- ~305 downloads/month across all cities
- 5% conversion to Pro at ~$12 avg = ~$183/month
- Plus ad revenue from free users: ~$30-50/month
- **Total: ~$200-250/month**

## Risk Mitigation
- **API reliability**: DB transport.rest is community-maintained. Have fallback to direct HAFAS API.
- **Apple rejection**: One app, not ten. City selection is a feature, not a template.
- **Berlin users**: Don't break existing Berlin experience. Berlin stays default for existing users.

---

## /autoplan CEO Review (2026-04-28)

### Scope Decision: SELECTIVE EXPANSION
Ship multi-city in v2.0 (Phases 1-5). Defer monetization (Phase 6) to v2.1.
Rationale: Validate demand before building paywall. 96 users is too few to monetize.

### Premise Assessment

| Premise | Verdict | Notes |
|---------|---------|-------|
| P1: 305 downloads/month | Optimistic | Likely 150-250 without marketing; "Berlin" ASO destroyed by rename |
| P2: 5% Pro conversion | Overly optimistic | Transit apps see 1-3%; budget $73-110/month |
| P3: One app, not ten | Valid | Apple 4.3 compliance + strategic consolidation |
| P4: DB transport.rest reliable | Risky | Community-maintained, no SLA, radar quality untested |
| P5: RevenueCat | Deferred | Native StoreKit 2 preferred; TipJarStore already exists |
| P6: 4-week timeline | Fiction for full scope | 4 weeks feasible for Phases 1-5 only |

### API Validation Gate (BLOCKING)
Before committing to 10 cities, test `v6.db.transport.rest/radar` for Munich:
```bash
curl "https://v6.db.transport.rest/radar?north=48.2&west=11.5&south=48.1&east=11.7&duration=30&results=10"
```
If radar returns empty/error for non-VBB cities, the app degrades to departures-only (no live vehicle map). This changes the product value proposition fundamentally.

### Kill Criteria
- Minimum 50 downloads/month from non-Berlin cities within 60 days of v2.0 launch
- If not met, reassess national expansion before building Pro tier

### Error & Rescue Registry

| Error | Impact | Rescue |
|-------|--------|--------|
| DB API `/radar` empty outside Berlin | Core feature broken in 9 cities | Departures-only mode with clear UI distinction |
| ASO reset loses Berlin rankings | Downloads drop | Keep "Berlin" in keywords, subtitle mentions Berlin first |
| Favorites broken across cities | Confusing UX | Add `cityId` to Favorite model |
| Offline stops download fails | No search in new cities | Bundle top-50 per city |
| API rate-limits | All cities degrade | Request throttling + aggressive caching |

### Failure Modes Registry

| Mode | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| DB API radar empty outside Berlin | Medium | Critical | Test gate; graceful degradation |
| ASO rankings drop after rename | High | High | Phase rename; keep Berlin keywords |
| Favorites without city context | High | Medium | Add cityId to Favorite model |
| Offline DB Berlin-only grid hardcoded | Certain | Medium | Per-city grid configs |
| 4-week timeline for full scope | High | Low | Reduced to Phases 1-5 only |
| Privacy positioning conflict with ads | Medium | Medium | Deferred to v2.1 with positioning review |

### What Already Exists

| Sub-problem | File | Status |
|------------|------|--------|
| City configuration | CityConfig.swift | Done (10 cities) |
| City persistence | CityManager.swift | Done |
| Service switching | TransportService, VehicleRadarService | Done |
| API abstraction | Config.swift | Done |
| Model generics | TransportModels.swift | Partial (aliases) |
| Offline stops | OfflineStopsDatabase.swift | Berlin-only |
| Favorites | FavoritesService.swift | No city association |
| Payments | TipJarStore.swift | Tip jar only |
| Map default region | TransportMapView.swift:58 | Berlin hardcoded |

### NOT in Scope (v2.0)

- RevenueCat / Pro tier (v2.1 -- validate demand first)
- Ad integration (v2.1 -- privacy positioning review needed)
- Live Activities extension (v2.1)
- City-themed alternate icons (v2.1)
- GTFS-RT fallback (infrastructure sprint)
- Portfolio consolidation with MyStop Berlin (separate /office-hours decision)

### CEO Dual Voices Summary
- **Codex (8 findings):** Revenue model is unearned, expansion axis unproven, API quality untested, no decision gates, ASO reset risk, ads contradict privacy positioning
- **Claude subagent (6 findings):** Radar endpoint may not work outside Berlin, MyStop Berlin conflict, favorites lack city association, offline DB Berlin-only, timeline unrealistic, German localization gaps
- **Consensus:** 5/6 confirmed. 1 disagree (expansion axis -- Codex says prove Berlin depth first; Claude says cities are viable if scoped)

<!-- AUTONOMOUS DECISION LOG -->
## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|---------------|-----------|-----------|----------|
| 1 | CEO | Defer monetization to v2.1 | Mechanical | P3 (pragmatic) | Validate demand before paywall | Full v2.0 with monetization |
| 2 | CEO | Accept expansion premise with API gate | Taste | P6 (action) + P1 (completeness) | Cities are viable if radar works; add kill criteria | Berlin-depth-first (Codex) |
| 3 | CEO | Use native StoreKit 2, not RevenueCat | Mechanical | P4 (DRY) | TipJarStore already uses StoreKit | RevenueCat (adds second payment system) |
| 4 | CEO | 4-week timeline for Phases 1-5 only | Mechanical | P3 (pragmatic) | Full scope is 8 weeks; ship cities first | 4-week full scope |
| 5 | CEO | Add cityId to Favorite model | Mechanical | P1 (completeness) | Cross-city favorites will break without it | Keep current model |
| 6 | CEO | Keep "Berlin" in ASO keywords after rename | Mechanical | P3 (pragmatic) | Protect existing 96 downloads | Clean break to "German" branding |
| 7 | Design | City pill/header on map view (not buried in Settings) | Mechanical | P5 (explicit) | Users must always know which city they're viewing | City only in Settings |
| 8 | Design | Specify all interaction states for new flows | Mechanical | P1 (completeness) | Loading/empty/error for city detection, offline stops, API switch | Leave to implementer |
| 9 | Design | Update DESIGN.md direction for multi-city | Mechanical | P1 (completeness) | "Berliner Precision" contradicts national scope | Keep Berlin-specific design doc |
| 10 | Design | Add radar degradation banner | Mechanical | P1 (completeness) | Users need to know why no vehicles are shown | Silent degradation |
| 11 | Design | Favorites grouped by city | Taste | P5 (explicit) | Users with multi-city favorites need grouping | Flat list (simpler) |
| 12 | Design | Per-city onboarding demo stops | Mechanical | P1 (completeness) | Munich user shouldn't see Alexanderplatz demos | Berlin demos for everyone |
| 13 | Design | Contrast-validate all 10 accent colors | Mechanical | P1 (completeness) | Stuttgart yellow/Dresden yellow fail WCAG AA | Use unchecked colors |
| 14 | Eng | Wire CityManager into ServiceContainer + views | Mechanical | P1 (completeness) | City switching is non-functional without it | Leave unwired |
| 15 | Eng | Add updateCity() to RouteService | Mechanical | P1 (completeness) | Route planning fails for non-Berlin | Keep VBB-pinned |
| 16 | Eng | Hide events card for non-Berlin cities | Mechanical | P3 (pragmatic) | Berlin-only API, no equivalent for other cities | Show broken events |
| 17 | Eng | Make widget city-aware via App Group | Mechanical | P1 (completeness) | Widget shows wrong data for non-Berlin users | Keep Berlin widget |
| 18 | Eng | Add per-city capability flags to CityConfig | Mechanical | P5 (explicit) | Explicit > detecting empty radar response | Runtime detection |
| 19 | Eng | Use bounding box for city detection, not center distance | Mechanical | P5 (explicit) | Handles suburbs and overlapping metros | 50km center radius |
| 20 | Eng | Validate ALL API endpoints for Munich + Hamburg before ship | Mechanical | P1 (completeness) | One radar curl is insufficient | Single endpoint gate |
| 21 | Eng | Manual city selection is sticky (not overridden by location) | Mechanical | P5 (explicit) | Users expect their choice to persist | Auto-re-detect |
| 22 | Eng | OfflineStopsDatabase: per-city cache keys + city param | Mechanical | P1 (completeness) | Berlin-only storage breaks multi-city | Shared singleton |
| 23 | Eng | Favorites model: add cityId, widget sync includes cityId | Mechanical | P1 (completeness) | Cross-city favorites need city context | No migration |
| 24 | CEO (re-run) | User Challenge presented at premise gate; user chose "keep 10 cities, defer rename only" | User decision | — | User has context models lack (commitment, taste, distribution plans). 10-city picker already shipped — sunk effort to undo | Pivot to Berlin+Munich; keep original plan as-is |
| 25 | CEO (re-run) | App rename deferred until non-Berlin downloads ≥ 30/mo for 60 days | Mechanical | P3 (pragmatic) | Protects ASO equity in only proven market; rename remains a tool, used after demand validation | Rename in v2.0 |
| 26 | CEO (re-run) | Per-city capability flags (`supportsRadar`, `supportsEvents`, `supportsRoutes`) become ship-blocking — non-Berlin cities must degrade gracefully without damaging pooled rating | Mechanical | P1 (completeness) | Silent partial failure damages Berlin reviews via single SKU. Capability flags = explicit degradation | Runtime-detect (could trigger transient false positives) |
| 27 | CEO (re-run) | API endpoint validation matrix for Munich + Hamburg becomes hard ship gate (curl every endpoint type before code lock) | Mechanical | P1 (completeness) | One-curl gate from prior run is too soft; silent partial failures are the dominant risk | Single radar curl |
| 28 | CEO (re-run) | Trademark/permission risk for transit authority logos and colors flagged for legal review before any logo ships | Mechanical | P1 (completeness) | Currently using BVG/MVG/HVV/RMV brand colors without licenses; one DMCA complaint pulls the SKU | Ship logos uncleared |
| 29 | Design (re-run) | Map header pill becomes ship-blocking before any non-Berlin city activates | Mechanical | P5 (explicit) | Without it, city is invisible state — Munich user has no way to know they're in Munich | Defer pill |
| 30 | Design (re-run) | Onboarding flow inverted — city picker is screen 1, all copy uses `currentCity.name` | Mechanical | P1 (completeness) | 11 hardcoded Berlin surfaces contradict multi-city promise on first launch | Patch copy in place |
| 31 | Design (re-run) | Non-radar cities get a deliberate "Departures Mode" visual distinction (no vehicle layer, no live pulse, capability chip in pill, no banner-card chrome) | Mechanical | P5 (explicit) + P1 | Banner-on-broken-Berlin reads as bug. Departures Mode reads as deliberate. | Banner-only approach |
| 32 | Design (re-run) | `CityPickerView` rebuild — list rows + capability chips + Near-You section + dismiss-lock on first launch + loading/empty/error states | Mechanical | P1 (completeness) | Current grid breaks first-launch lock; missing capability chips; zero state coverage | Keep current grid |
| 33 | Design (re-run) | Add `accentColorOnLight` + `accentColorOnDark` tokens to `CityConfig`; never rely on color alone to identify city | Mechanical | P1 (completeness) | More cities fail WCAG AA than plan claims; color-blind palette collapses into 3 clusters | Single accent |
| 34 | Design (re-run) | Transit authority logos NOT shipped without legal clearance; accent colors only (functional, hard to claim TM) | Mechanical | P1 (completeness) + P3 (pragmatic) | DMCA precedent on raster logos; functional color usage is much harder to claim | Ship logos uncleared |
| 35 | Eng (re-run) | `ServiceContainer.updateCity()` extended to clear `predictiveLoader`, switch `OfflineStopsDatabase`, gate `EventsService`, reload widget, update tile preloader | Mechanical | P1 (completeness) | Current updateCity propagates to 3/8 city-aware components — silent stale data on switch | Update only Transport/Route/Radar |
| 36 | Eng (re-run) | `ServiceContainer.updateCity()` becomes `async`; in-flight tasks tracked + cancelled per-service on city change | Mechanical | P5 (explicit) | Race condition: vehicleRadar Task dispatch is unstructured + URLSession in-flight uses old baseURL | Fire-and-forget |
| 37 | Eng (re-run) | `OfflineStopsDatabase` becomes non-singleton actor keyed by cityId; per-city grid coordinates from `CityConfig.boundingBox`; `searchLocations` short-circuit guarded by cityId | Mechanical | P1 (completeness) | Berlin-pinned blast radius blocks multi-city correctness | Singleton with switch parameter |
| 38 | Eng (re-run) | Berlin migration: keep `berlin_all_stops_cached.json` filename mapped to `cityId == "berlin"`; namespace others as `{cityId}_all_stops_cached.json` | Mechanical | P3 (pragmatic) | Existing Berlin user upgrade preserves cache | Force re-download |
| 39 | Eng (re-run) | Capability flags two-layer pattern: service entry (don't fetch, throw `.unsupportedForCity`) + UI render (don't show layer/card) | Mechanical | P5 (explicit) + P1 | Service-only leaves spinners; UI-only fires the network call. Two-layer is the only safe pattern. | Single-layer |
| 40 | Eng (re-run) | `Favorite` model adds `var cityId: String?`, dedupe predicate is per-(stopId, cityId), `WidgetSavedStop` extends with cityId+apiBaseURL, deep links carry `?city=` | Mechanical | P1 (completeness) | 3 corruption paths: silent merge of cross-city same-stopId; widget polls VBB regardless; deep link resolves wrong city | Single-field migration |
| 41 | Eng (re-run) | API endpoint validation matrix as `scripts/validate-city-endpoints.sh` (curl + jq shape-check), NOT XCTest | Mechanical | P3 (pragmatic) | Community API flakiness dominates CI in tests; script runs once before ship-lock | XCTest integration |
| 42 | Eng (re-run) | Drop `berlin_all_stops.json` from non-Berlin first-launch fetches | Mechanical | P3 (pragmatic) | Wasted bundle storage on Munich install; Berlin stops served as offline matches in non-Berlin | Keep bundled file |
| 43 | Eng (re-run) | `MapTilePreloader` reads `cityManager.currentCity` instead of hardcoded `preloadBerlinTiles()` | Mechanical | P5 (explicit) | Bandwidth waste for Munich-default user | Keep Berlin preload |
| 44 | Eng (re-run) | `ios/TransportWidget.swift` audited for ship status: delete if legacy, gate behind capability flag if shipped | Pragmatic | P4 (DRY) | Two widgets is wrong number; uncertain ship status from grep alone | Keep both |
| 45 | Eng (re-run) | Minimum 5 test files (~150 lines) become ship gate: `CityConfigTests`, `CityManagerTests`, `ServiceContainerUpdateCityTests`, `FavoriteCityIdMigrationTests`, `OfflineStopsDatabaseCityTests` | Mechanical | P1 (completeness) | Zero coverage of new abstraction; race conditions need regression tests | Skip new tests |
| 46 | Eng (re-run) | TransportMapView extraction (MapHeaderPill, EventsCard, etc.) deferred to v2.1 | Pragmatic | P3 (pragmatic) | 1874 lines is large but mechanical not architectural; ship the v2.0 city work first | Refactor in v2.0 |
| 47 | Gate | Final gate: APPROVED AS-IS by user; T1=Berliner Precision, T2=PRODUCT_DISPLAY_NAME→"Transit Map", T3=flat favorites with city label, T4=audit ios/TransportWidget.swift | User decision | — | Plan ready to drive v2.0 implementation. /ship when work is done. | Override / interrogate / revise |
| 48 | Gate (pass 3) | Land v1.7 (PR #6) and shift v1.8 axis to distribution sprint | User decision | — | All ship-blockers closed; capability gates protect Berlin. Subagent: 96 dl/mo is demand-discovery failure, all product axes are premature optimization | Validate Munich (A), deepen Berlin (B), polish multi-city first (D) |
| 49 | CEO (pass 3) | Land v1.7 now — capability gates make it safe; ASO equity preserved; pooled-rating risk neutralized | Mechanical | P6 (action) + P3 (pragmatic) | 4 review rounds + 2 adversarial passes + on-simulator QA + 62/62 tests; Berlin behavior unchanged | Hold for additional polish |
| 50 | CEO (pass 3) | v1.8 = distribution sprint (ASO audit + Apple Search Ads $300 test + Featured submission + landing page) | Mechanical (after gate 48) | P6 (action) + P5 (explicit) | Without distribution data every product axis is guessing; end-of-v1.8 branch point produces actionable decision | Continue building features without traffic data |
| 51 | Design (pass 3) | Landing page becomes v1.8 ship-gate before Featured submission — Cloudflare Pages, Berliner Precision aesthetic, ~4h | Mechanical | P1 (completeness) | Apple Editorial reviewers click marketingUrl; current value is GitHub repo (signals hobbyist not Featured-eligible) | Use existing GitHub repo URL |
| 52 | Design (pass 3) | Screenshot 5 = `CityPickerView` with capability chips; keep screenshots 1-4 Berlin-led | Mechanical | P3 (pragmatic) | Differentiator for Editorial curators scanning portfolio breadth, but Berlin ASO equity preserved on the lead | Full multi-city refresh (dilutes Berlin equity) |
| 53 | Eng (pass 3) | `FavoriteRow` per-stop API resolution: mirror widget's `WidgetSavedStop {cityId, apiBaseURL}` pattern | Mechanical | P1 (completeness) | Multi-city favorites currently break in-app same way widget would have pre-v1.7; loudest first-week trust break for paid-traffic Munich install | Filter rows by currentCity (loses cross-city favorites) |
| 54 | Eng (pass 3) | De-Berlinify the first 60 seconds: `WelcomeOverlayView.swift:100`, `TransportMapView.swift:1785`, `OnboardingView.swift:501,582,588,956` use `cityManager.currentCity.name`/`transitAuthority` | Mechanical | P5 (explicit) | A Munich-keyword installer reading "Berlin" 3× in 30 seconds bounces — directly torches the conversion the distribution sprint is measuring | Defer to v1.9 (full onboarding inversion) |
| 55 | Eng (pass 3) | Lightweight privacy-preserving instrumentation: local UserDefaults counters + anonymous POST to self-hosted Cloudflare Worker on activation milestones (`app_open`, `onboarding_complete`, `city_picked`, `first_favorite_saved`) | Mechanical | P1 (completeness) | "Did the campaign convert" question can't be answered by ASC Analytics alone; preserves no-tracking positioning | Skip instrumentation (campaign data is unactionable noise) |
| 56 | Eng (pass 3) | Map header city pill DEFERRED to v1.9 — nav title carries the load while v1.8 paid traffic targets Berlin keywords | Pragmatic | P3 (pragmatic) | Pill becomes mandatory once ASO targets generic German keywords; v1.8 doesn't | Build pill now (premature for v1.8 traffic mix) |
| 57 | Eng (pass 3) | API endpoint validation matrix DEFERRED to v1.9 — Munich live vehicles aren't shipping in v1.8 | Pragmatic | P3 (pragmatic) | The script is the gate to flip flags, not the gate to ship distribution-focused v1.8 | Run matrix now (no v1.8 user impact) |
| 58 | Eng (pass 3) | About / Help / Welcome copy: gate "Live vehicle positions" / "BVG" claims on `currentCity.supportsRadar` / `transitAuthority` | Mechanical | P1 (completeness) | First-screen honesty for non-Berlin installs; pairs with eng task 54 (de-Berlinify) | Defer to v1.9 |
| 59 | Eng (pass 3) | FavoritesView mixed-city indicator DEFERRED to v1.9 — multi-city favorites only emerge after switching cities + saving on both, vanishingly rare in v1.8 traffic | Pragmatic | P3 (pragmatic) | Eng task 53 (per-stop API) prevents the actually-broken case; indicator is polish | Build indicator now |

---

## /autoplan Design Review (2026-04-28)

### Design System Evolution Required

DESIGN.md needs updating from "Berliner Precision" to a multi-city design system.

**Keep:** 8pt grid, monospacedDigit for times, rounded for station names, status colors, line badge patterns, Hero ETA, Live Badge, Departure Row.

**Update:**
- Direction: "German Transit Precision" -- functional clarity across all cities, not Berlin-specific Bauhaus identity
- Primary color: `#115D97` stays as app brand color; city accent colors are SECONDARY and used for the city header pill, city picker badges, and settings accent only
- Line badges: per-city authentic colors from each transit authority (not just BVG/VBB)
- Add: city header/pill pattern on map view
- Add: radar degradation banner pattern

### City Picker UI Specification

**First launch flow:**
1. Location permission already requested in onboarding
2. If location available: auto-detect nearest city from `CityConfig.allCities` (compare distance to each `centerCoordinate`)
3. If closest city is within 50km: auto-select, show brief toast "Detected: [City]"
4. If closest city is >50km OR location denied: show city picker sheet (modal, not dismissable on first launch)

**City picker layout:**
- NavigationStack with "Choose Your City" title
- List of all 10 cities, each row shows:
  - City accent color circle (12pt)
  - City name in `.fontDesign(.rounded)`
  - Transit authority in `.caption` secondary
  - "Live map" badge (green) for Berlin, "Departures" badge (blue) for others

**Settings -> Change City:**
- Same city picker as above, dismissable
- Switching city: services update, map pans to new city center, offline stops load

### Map City Header Pill

Persistent pill at top of map (below safe area):
```
[accent dot] [City Name] [chevron.down]
```
Tap opens city picker. Pill uses city accent color for the dot. Text in `.fontDesign(.rounded)`.

### Radar Degradation Banner

When `VehicleRadarService.fetchVehicles()` returns empty for the current city:
```
[info.circle] Departures available -- live vehicle positions coming soon
```
Banner appears below the city header pill. `.caption` font, `.secondary` foreground. Dismissable with X button, persists per city in UserDefaults.

### Onboarding Demo Stops Per City

Each city needs 3-5 demo stops for the onboarding `DemoScreen`. For v2.0:
- Berlin: keep existing 8 stops (Alexanderplatz, Hauptbahnhof, etc.)
- Other cities: use the 3 busiest stops from each city's bundled stop data
- Sample departures: generate mock departures matching the city's supported products

### Favorites UX

Favorites show ALL cities in a single list. Each `FavoriteRow` adds a city label in `.caption` below the stop name. No grouping by city (keeps it simple, avoids empty section headers for cities with 0 favorites). Filter option in v2.1 if needed.

### Interaction States for New Flows

| Flow | Loading | Empty | Error | Partial |
|------|---------|-------|-------|---------|
| City auto-detect | "Finding your city..." spinner | City picker sheet | City picker sheet | N/A |
| Offline stops download | "Loading stops for [City]..." | "No stops available" + retry | "Couldn't load stops" + retry | Show cached + badge "Updating..." |
| City switch | Map pans + spinner | N/A | "Couldn't connect to [City] network" + retry | N/A |
| Radar fetch (empty) | N/A | Degradation banner | Degradation banner | N/A |

### Accent Color Contrast

Colors needing dark variants for light backgrounds:
- Stuttgart `#ffc20e` -> dark variant `#b38a00`
- Dresden `#fdc500` -> dark variant `#9e7a00`

All other accent colors pass WCAG AA against white/black backgrounds.

---

## /autoplan Eng Review (2026-04-28)

### Critical Architecture Gaps

**1. CityManager is not wired into the app.**
`CityManager` exists but is not referenced by `ServiceContainer`, `TransportMapView`, `ContentView`, or any view. Services initialize with `.berlin` defaults and nobody calls `updateCity()` when the user switches cities.

**Fix:** Add `CityManager` as an `@State` in `BerlinTransportMapApp` and pass via `.environment()`. In `TransportMapView`, observe `CityManager.currentCity` and call `updateCity()` on all services when it changes. Add `CityManager` to `ServiceContainer` init.

**2. RouteService is permanently VBB-pinned.**
`RouteService.swift:7` hardcodes `baseURL = "https://v6.vbb.transport.rest"`. No `updateCity()` method, no CityConfig parameter. Route planning silently uses wrong API for non-Berlin cities.

**Fix:** Add `init(city: CityConfig = .berlin)` and `updateCity(_ city: CityConfig)` matching `TransportService` pattern.

**3. EventsService is Berlin-only.**
`EventsService.swift:8` hardcodes `https://api.berlin.de/events/`. No equivalent API for other cities.

**Fix:** Hide the events card for non-Berlin cities. Add `CityConfig.supportsEvents: Bool` (true only for Berlin).

**4. Widget extension entirely Berlin-hardcoded.**
`DepartureWidget.swift` and `ios/TransportWidget.swift` hardcode VBB URLs, Berlin coordinates, Berlin stop names.

**Fix:** Widget reads current city from App Group UserDefaults. `WidgetSavedStop` model adds `cityId` and `apiBaseURL` fields. Widget uses the saved city's API endpoint.

### Data Model Migration

**Favorite model:** Add `var cityId: String?` to `@Model class Favorite`. SwiftData handles additive optional properties automatically (no explicit migration plan needed). Code treats `nil` as `"berlin"` for backward compatibility.

**Widget sync:** `FavoritesService.syncToWidget()` must include `cityId` and the corresponding `apiBaseURL` in the App Group payload.

**CommuteAlertManager:** Deep link format changes from `berlintransportmap://departures/STOP_ID` to `berlintransportmap://departures/STOP_ID?city=CITY_ID`.

### OfflineStopsDatabase Rewrite

Current state: singleton with Berlin-only filenames, one in-memory stop set, Berlin-only grid coordinates in `downloadAndCache()`.

Required changes:
- Cache file names keyed by city: `{cityId}_all_stops_cached.json`
- `loadIfNeeded()` accepts `CityConfig` parameter
- Per-city grid coordinates for download (each city gets its own lat/lon grid)
- Bundle top-50 stops per city as `{cityId}_top_stops.json`
- `searchLocations()` in TransportService should NOT short-circuit to offline results for cities without downloaded stops -- fall through to API

### Per-City Capability Flags

Add to `CityConfig`:
```swift
let supportsRadar: Bool      // true for Berlin (validated), false for others until tested
let supportsEvents: Bool     // true only for Berlin
let supportsRoutes: Bool     // true for all (same HAFAS endpoint)
```

Radar degradation uses `CityConfig.supportsRadar` flag, NOT empty fetch result (which could be transient).

### API Endpoint Validation Matrix

Before shipping v2.0, validate ALL endpoints for at least Munich and Hamburg:

| Endpoint | Berlin (VBB) | Munich (DB) | Hamburg (DB) |
|----------|-------------|-------------|-------------|
| `/locations/nearby` | Validated | TODO | TODO |
| `/locations?query=X` | Validated | TODO | TODO |
| `/stops/:id/departures` | Validated | TODO | TODO |
| `/radar` | Validated | TODO | TODO |
| `/trips/:id` | Validated | TODO | TODO |
| `/journeys` | Validated | TODO | TODO |

### City Detection

Use `CityConfig.boundingBox` (already modeled) instead of center-distance. Check if user location is within any city's bounding box. If inside multiple or none, show city picker. Manual selection is sticky (persisted in UserDefaults, not overridden by location changes).

### Eng Completion Summary

| Dimension | Score | Notes |
|-----------|-------|-------|
| Architecture | 4/10 | CityManager unwired, RouteService/EventsService Berlin-locked |
| Test coverage | 2/10 | Near-zero for new flows; test plan written |
| Performance | 7/10 | Existing patterns adequate |
| Security | 8/10 | No new attack surface |
| Error handling | 4/10 | City switch + API degradation paths undefined |
| Deployment risk | 6/10 | 4 weeks tight but feasible if architecture addressed first |

### Test Plan

Full test plan at: `~/.gstack/projects/dautovri-berlin-realtime-map/feat-germany-expansion-test-plan-20260428-105204.md`

### Eng Dual Voices Summary
- **Codex (7 findings):** CityManager unwired, OfflineStopsDatabase rewrite underestimated, API gate too weak (test all endpoints), Favorite migration needs widget sync, radar degradation needs capability flags, city detection should use bounding boxes, scope contradictions in plan
- **Claude subagent (7 findings):** ServiceContainer doesn't propagate city, RouteService VBB-pinned, EventsService Berlin-only, widget Berlin-hardcoded, SwiftData migration, deep link needs city, TransportMapView too large
- **Consensus:** 5/6 confirmed. 1 disagree (deployment timeline)

---

## Cross-Phase Themes

**Theme 1: API quality is assumed, not validated.** Flagged in CEO (P4 premise), Design (radar degradation), and Eng (endpoint validation matrix). All 3 phases independently identified that the plan treats DB transport.rest as equivalent to VBB without testing. High-confidence signal: test all endpoints for Munich + Hamburg before committing.

**Theme 2: CityManager exists but isn't connected to anything.** Flagged in Design (city picker needs wiring) and Eng (ServiceContainer + views don't reference CityManager). The city state management is the foundational architecture change, and it's not done yet.

**Theme 3: Berlin assumptions are deeply embedded.** Flagged in CEO (OfflineStopsDatabase), Design (DESIGN.md identity, onboarding), and Eng (RouteService, EventsService, widget, deep links). The plan lists 10 files to refactor but the actual blast radius is larger: widget extension, commute alerts, help text, events, route planning.

**Theme 4: Scope and timeline don't match.** Flagged in CEO (4 weeks is fiction for full scope) and Eng (need architecture + endpoint matrix first). Resolved by deferring monetization to v2.1, but even Phases 1-5 need the architecture work identified in the eng review before estimates are reliable.

---

## GSTACK REVIEW REPORT

| Skill | Status | Findings | Via |
|-------|--------|----------|-----|
| plan-ceo-review | issues_open | 6 premises challenged, scope reduced to Phases 1-5 | autoplan |
| plan-design-review | issues_open | 7 design gaps specified, DESIGN.md evolution required | autoplan |
| plan-eng-review | issues_open | 7 architecture gaps, test plan written | autoplan |
| autoplan-voices (CEO) | complete | 5/6 confirmed, 1 disagree | codex+subagent |
| autoplan-voices (Design) | complete | 6/7 confirmed, 1 disagree | codex+subagent |
| autoplan-voices (Eng) | complete | 5/6 confirmed, 1 disagree | codex+subagent |
| plan-ceo-review (re-run) | issues_open | 7 findings; user resolved User Challenge to "keep 10 cities, defer rename" | autoplan |
| plan-design-review (re-run) | issues_open | 7 findings (C1-C3 critical); 8 hardcoded surfaces inventoried | autoplan |
| plan-eng-review (re-run) | issues_open | 12 findings; 5 Berlin-pinned components remain; arch score 5/10 | autoplan |
| autoplan-voices (CEO re-run) | complete | 6/6 confirmed (User Challenge surfaced + resolved at gate) | codex+subagent |
| autoplan-voices (Design re-run) | complete | 6/7 confirmed, 1 disagree (brand-name evolution = taste) | codex+subagent |
| autoplan-voices (Eng re-run) | partial | subagent-only — codex hit usage limit | subagent-only |

---

## /autoplan Pass 3 (2026-04-29T09:00Z) — Land v1.7 + v1.8 axis

**Context:** PR #6 open with 12 commits + 22 new tests. v1.7 multi-city foundation through 2 review rounds + 2 adversarial passes. All ship-blockers closed. Codex still hitting usage limit (resets Apr 30) — this pass is **subagent-only**.

### Pass-3 questions

1. **Should v1.7 land?** YES — capability gates protect Berlin, ASO unchanged, all known ship-blockers closed.
2. **What's the v1.8 axis?** **C) Distribution sprint** (user-confirmed at premise gate). The 6 prior months of work shipped foundation; the next 6 sell what was built. 96 dl/mo is a demand-discovery failure, not a coverage failure.

### v1.8 plan (concrete, sequenced)

**Week 1-2 — ASO baseline:**
1. Run `/aso-audit` skill on current Berlin Transport Map listing
2. Test subtitle/keyword variants on Berlin terms
3. Get baseline conversion rate from impressions → downloads
4. Build a landing page on Cloudflare Pages (Berliner Precision aesthetic) — replaces current GitHub repo URL as `marketingUrl` in `metadata/version/1.7/`

**Week 2-3 — Paid traffic test:**
5. $300 Apple Search Ads on Berlin transit keywords
6. Goal: learn baseline CAC + impression→download conversion (data we don't have)

**Week 3 — Featured submission:**
7. Submit to App Store Featured (Made in Germany / Built for Berlin angle)
8. Pitch deck: 5 screenshots + 30s preview
   - Screenshots 1-4: Berlin-led (Hero ETA, live U-Bahn, departure sheet, favorites)
   - Screenshot 5: `CityPickerView` with capability chips (the "and 9 more" reveal)
   - 30s preview: silent Berlin commute, no UI chrome, closing card "No ads. No accounts. No tracking."

**Throughout — eng polish (background, ~10h total):**
9. **De-Berlinify first 60 seconds** for non-Berlin installs (`WelcomeOverlayView.swift:100`, `OnboardingView.swift:501,582,588,956`, `TransportMapView.swift:1785`) — use `cityManager.currentCity.name`/`transitAuthority`
10. **`FavoriteRow` per-stop API resolution** — mirror `WidgetSavedStop {cityId, apiBaseURL}` pattern
11. **Lightweight distribution instrumentation** — local UserDefaults counters + anonymous Cloudflare Worker POST on activation milestones (`app_open`, `onboarding_complete`, `city_picked`, `first_favorite_saved`); preserves no-tracking positioning while answering "did the campaign convert"

### Pass-3 explicitly DEFERRED to v1.9

- Map header city pill (autoplan row 29) — nav title carries the load while v1.8 paid traffic targets Berlin keywords
- API endpoint validation matrix script — Munich live vehicles aren't shipping in v1.8
- FavoritesView mixed-city indicator — vanishingly rare in v1.8 traffic mix
- TransportMapView extraction (1900+ lines) — mechanical not architectural
- Test backfill for round-2 fixes (AppDelegate cityId, alert sheet cityId) — manual coverage exists, low regression risk
- Full onboarding inversion (11 hardcoded surfaces) — task 9 covers the 5 highest-impact surfaces; rest stay default-Berlin

### v1.8 branch point (end of sprint)

End of v1.8 produces a real decision:
- **(a)** ASO + ads convert 96 → 200+ dl/mo with stable CAC → product is fine, distribution was the bottleneck → scale spend, return to product axes (A: Munich, B: Watch, etc.)
- **(b)** Impressions flat or conversion broken → product itself isn't what people search for → `/office-hours` for positioning rethink

Either outcome is actionable. Building Munich live vehicles or a Watch app produces no decision.

### Pass-3 review log

| Skill | Status | Findings | Source |
|-------|--------|----------|--------|
| plan-ceo-review (pass 3) | clean | Land v1.7 + v1.8=distribution recommended; user confirmed | subagent-only |
| plan-design-review (pass 3) | issues_found | 3 v1.8 design tasks (landing page, screenshot 5, widget per-stop) | subagent-only |
| plan-eng-review (pass 3) | issues_found | 3 v1.8 eng tasks (de-Berlinify 60s, FavoriteRow per-stop, instrumentation) | subagent-only |
| autoplan-voices (CEO pass 3) | partial | subagent-only — codex usage limit | subagent-only |
| autoplan-voices (Design pass 3) | partial | subagent-only — codex usage limit | subagent-only |
| autoplan-voices (Eng pass 3) | partial | subagent-only — codex usage limit | subagent-only |

### Cross-phase theme (pass 3)

**"De-Berlinify the first 60 seconds before sending paid traffic."** Both design subagent (onboarding hygiene minimum 2 surfaces) and eng subagent (top priority eng task: hardcoded Berlin strings) independently flagged the same thing: a Munich-keyword paid installer reads "Berlin" 3× in 30 seconds and bounces. This is the highest-leverage single fix protecting v1.8 spend. Sequence: ship before Apple Search Ads goes live, or the campaign data is contaminated.

---

## /autoplan Re-Review (2026-04-28T17:04Z)

### State at re-run
Recent commits implemented part of the prior eng review:
- ✅ CityConfig added (10 cities)
- ✅ CityManager wired into ServiceContainer + views
- ✅ TransportService / RouteService / VehicleRadarService accept `CityConfig`
- ✅ CityPickerView created (grid-based)
- ✅ Onboarding uses selected city name
- ❌ EventsService still hardcodes `https://api.berlin.de/events/`
- ❌ Widget still hardcodes `https://v6.vbb.transport.rest` + Alexanderplatz/Hauptbahnhof
- ❌ OfflineStopsDatabase still uses `berlin_all_stops_cached.json` (singleton)
- ❌ Favorite model has no `cityId` (cross-city ambiguity)
- ❌ CityConfig has no `supportsRadar` / `supportsEvents` / `supportsRoutes` flags
- ❌ Zero tests for CityConfig / CityManager / multi-city flows
- ❌ TransportMapView is 1874 lines (still growing)
- ❌ API endpoint validation matrix for Munich/Hamburg not run
- ❌ ASC display name still "Berlin Transport"; project bundle ID + INFOPLIST keys still Berlin-branded

### CEO Re-Review — Dual Voices

**Codex (CEO, re-run):** Premises mostly assumed. More cities is wrong first axis — current product promise is "watch Berlin transit move in real time," not "generic German departures." Renaming burns the only proven keyword equity for an unproven national thesis. API failure mode is silent partial failure: empty radar / weak search / city quirks read as app bugs and damage Berlin ratings via the pooled SKU. Trademark risk for transit logos/colors flagged but unaddressed. CPPs are theater without paid traffic. Scope (10 cities at once, full rebrand, infrastructure for every city, equal-SKU treatment) is "ten support surfaces" for a solo developer.

**Claude subagent (CEO, re-run):** 96 dl/mo is a *demand-discovery* failure, not a *coverage* failure — geometric weakness multiplication if expanded blindly. Premise P3 ("one app, not ten") accepted uncritically: per-city ASC entries with shared SwiftPM core may dominate (Citymapper precedent). Missing alternatives: Apple Watch app (transit is THE watch use case, near-zero competition in DACH), widget-first product, iMessage share-stop deep link, MyStop Berlin consolidation. Competitive risk HIGH: DB Navigator (50M downloads, gov-backed) + Citymapper own coverage; the moat is *Berlin aesthetic*, erased by going wider. Realistic wedge: **Berlin + Munich only**. Recommends not renaming until non-Berlin downloads exceed 30/mo.

### CEO Dual Voices — Consensus Table

| Dimension | Claude subagent | Codex | Consensus |
|-----------|-----------------|-------|-----------|
| 1. Premises valid? | NO (assumed) | NO (assumed) | CONFIRMED — premises lack evidence |
| 2. Right problem to solve? | NO (demand, not coverage) | NO (dilutes core promise) | CONFIRMED — wrong first axis |
| 3. Scope calibration correct? | NO (4 weeks fiction; B+M only) | NO (10 cities = 10 surfaces) | CONFIRMED — overscoped |
| 4. Alternatives sufficiently explored? | NO (Watch, widget, MyStop merge) | NO (deeper Berlin, distribution) | CONFIRMED — missing axes |
| 5. Competitive/market risks covered? | NO (DB Navigator + Citymapper) | NO (Apple Maps, trademark) | CONFIRMED — competitor analysis missing |
| 6. 6-month trajectory sound? | NO (200 dl/mo regret) | NO (silent API failure + pooled ratings) | CONFIRMED — high regret risk |

**Consensus: 6/6 confirmed.** Both voices independently recommend a strategic pivot.

**Source:** codex+subagent. Both voices completed.

### CEO Re-Review Findings (high-severity)

1. **(CRITICAL) Wrong axis premise.** Both models say expansion is the wrong first move at 96 dl/mo. The bottleneck is *demand discovery in Berlin*, not *coverage*. Expanding multiplies a weak distribution motion across 10 zero-distribution markets.
2. **(CRITICAL) ASO rename trade is bad.** App title carries far more ASO weight than keywords. Renaming "Berlin Transport Map" → "German Transit Map" loses the only proven keyword in the only proven market. Munich users searching "MVG" find DB Navigator first regardless. Both models recommend keeping "Berlin Transport Map" until expansion is validated.
3. **(CRITICAL) API quality is unvalidated.** Switching 9 cities to community-maintained `v6.db.transport.rest` (single maintainer, no SLA) without endpoint validation. Failure mode is silent partial failure — empty radar, weak search, missing departures — interpreted as app bugs and damaging Berlin's pooled rating.
4. **(HIGH) Scope is fiction for a solo dev.** 10 cities × {API validation, offline stops, demos, contrast checks, QA, screenshots, support} ≈ 6+ weeks of pure scaffolding before product polish. Realistic wedge is Berlin + Munich (validates architecture + tests one new city).
5. **(HIGH) Competitive moat erased by going wider.** Current moat is Berliner Precision (aesthetic + Berlin-specific design). Multi-city kills that without replacing it. Apple Watch / widget-first are higher-leverage axes the plan never considered.
6. **(HIGH) Trademark risk unaddressed.** Plan uses MVG/HVV/RMV authority colors and logos in city pickers. None of these are licensed.
7. **(MEDIUM) Pooled rating risk.** One SKU means Munich users' frustration with empty radar damages Berlin reviews and rankings.

### USER CHALLENGE

Both models independently recommend the user reconsider the stated direction. This is **not auto-decided** — the user has context the models lack (commitment, timeline preference, opportunity cost, taste).

**What the user said:** "Transform Berlin Transport Map into German Transit Map covering all 10 major cities, full rename, all phases in 4 weeks."

**What both models recommend:** Pivot to **Berlin + Munich only**, defer rename until expansion proves itself, validate API endpoints first, run a 2-week Berlin distribution sprint in parallel.

**Why:** Premises (305 dl/mo, 4 weeks, DB API equivalent) are population math, not evidence. Distribution failure ≠ coverage failure. ASO rename burns proven equity. Solo-dev scope physics doesn't allow 10 cities at v2.0.

**What the models might be missing:** The user's domain knowledge of German transit usage patterns; possible non-monetary motivation (portfolio depth, learning); commitment already made (5 commits on branch); cross-promo opportunities with GoToAppleMaps; ASO experimentation tolerance.

**If the models are wrong, the cost of pivoting is:** ~3 days of refactoring undone or set aside (CityConfig already supports any number of cities — subset is ASC + UI, not code). Existing CityConfig still works for 2 cities. Delayed expansion if Munich proves out.

**If the models are right and the user proceeds anyway:** Burned ASO, 200-250 dl/mo across pooled SKU, silent API failures damaging ratings, 6-week solo timeline, no demand validation, regret in 6 months.

This challenge is surfaced at the final approval gate.

### Design Re-Review — Dual Voices

**Codex (design, re-run):** Plan is not ready from a UI/UX standpoint. Multi-city support feels like "Berlin broke" rather than a deliberate parent brand with supported networks. Non-radar cities must redesign as a separate "Departures Mode," not Berlin with a missing radar. First-launch hierarchy too weak: city context is buried in nav title and a menu while the app is still named Berlin Transport Map. State table is incomplete — 9 critical flows unspecified. Accent contrast claim in plan is false: Stuttgart, Dresden, **Düsseldorf** fail AA on light; Munich, Frankfurt, Leipzig, **Berlin barely passes** on dark; Cologne fails for white text on accent; color-blind palette collapses into 3 clusters. Onboarding is "fundamentally dishonest" for non-Berlin users — `WelcomeOverlayView` literally teaches "Tap any vehicle" while 9 cities may not have radar.

**Claude subagent (design, re-run):** Same root concern, more surgical. CityPickerView at 10 cities has real issues: 2-col grid optimizes symmetry not decision-making; no Near You section; no capability badges (`Live map` vs `Departures`); always-visible Done button breaks first-launch lock; zero loading/empty/error states. Onboarding hardcodes Berlin in 11+ surfaces (file:line list inline). Map header pill is the right persistent pattern but is not yet built — without it, city is invisible state. Recommends accent contrast tokens (`accentColorOnLight`, `accentColorOnDark`) on `CityConfig`. Visual taxonomy for non-radar cities: stops 12pt vs 10pt (now hero), drop live pulse on city pill, replace with tram/bus glyph, persistent `.caption2` "Departures live · vehicle map coming soon" — no banner-card chrome (chrome implies error). Brand voice: rewrite DESIGN.md Direction to "Functional Precision — multi-city in scope, Berlin remains visual exemplar."

### Design Dual Voices — Consensus Table

| Dimension | Claude subagent | Codex | Consensus |
|-----------|-----------------|-------|-----------|
| 1. First-launch info hierarchy | NO (pill not built) | NO (city buried in nav) | CONFIRMED — first-launch needs explicit city confirmation before map |
| 2. Missing states across new flows | NO (6+ unspecified) | NO (9 unspecified) | CONFIRMED — state table is incomplete |
| 3. Brand identity coherence | EVOLVE (Functional Precision) | KEEP (Berliner Precision additive) | DISAGREE — taste decision (kind, not coverage) |
| 4. Accent color contrast | NO (Stuttgart, Dresden + 3 borderline fail) | NO (more colors fail than plan admits) | CONFIRMED — plan understates failure count |
| 5. Onboarding for non-Berlin | NO (11 hardcoded surfaces) | NO ("fundamentally dishonest") | CONFIRMED — onboarding is Berlin-only |
| 6. Visual taxonomy of degradation | NO (banner not enough) | NO (needs separate mode) | CONFIRMED — non-radar cities need deliberate "Departures Mode" |
| 7. CityPickerView at 10 cities | NO (no states, no capability chips) | NO (grid wrong format) | CONFIRMED — picker needs rebuild |

**Consensus: 6/7 confirmed, 1 disagree (brand-name evolution — taste).**

**Source:** codex+subagent. Both voices completed.

### Design Re-Review Findings

**(CRITICAL) C1 — Map header pill not built.** Plan specified it. Code doesn't have it. A Munich user has no persistent indicator they're in Munich. Fix: ship the pill before any non-Berlin city goes live (`[8pt accent dot] [City name (.fontDesign(.rounded))] [chevron.down]`, top-leading below safe area, tap opens picker, hairline at `Color(.separator)` for chrome legibility on map tiles). Lines: TransportMapView.swift:438 (existing OfflineBanner anchor) is the natural insertion point.

**(CRITICAL) C2 — Onboarding contradicts multi-city promise across 11+ surfaces.**

| File:line | Issue |
|-----------|-------|
| `BerlinTransportMap/Views/WelcomeOverlayView.swift:100` | "Watch Berlin transit\nmove in real time" hardcoded |
| `BerlinTransportMap/Views/WelcomeOverlayView.swift:150,226,240` | "Browse Berlin", "Tap any vehicle" — wrong for non-radar cities |
| `BerlinTransportMap/Views/Onboarding/OnboardingView.swift:24,66` | Asks "Visiting Berlin?" |
| `BerlinTransportMap/Views/Onboarding/OnboardingView.swift:67-68,91,97` | Demo stops Alexanderplatz / Hauptbahnhof hardcoded |
| `BerlinTransportMap/Views/Onboarding/OnboardingView.swift:501,582,795` | Berlin testimonials, "map starts at Alexanderplatz" fallback |
| `BerlinTransportMap/Views/Onboarding/OnboardingView.swift:956,1054` | "Berlin Transport Map" share copy, "Keep Berlin Transit free" |
| `BerlinTransportMap/Views/SettingsView.swift:116` | Notifications copy Berlin-pinned |
| `BerlinTransportMap/BerlinTransportMapAboutView.swift:14,189` | About copy mentions Berlin trains/trams/buses |
| `BerlinTransportMap/Views/TransportMapView.swift:1728` | "Explore Berlin transit" hardcoded |
| `de.lproj/Localizable.strings:29` | Berlin-pinned in German loc |

Fix: invert onboarding flow → city picker is screen 1. All copy uses `\(currentCity.name)`. Demo stops bundled per city in `CityConfig` (top 3). Berlin testimonial gated behind `if city.id == "berlin"` until other-city testimonials exist.

**(CRITICAL) C3 — Non-radar cities must become "Departures Mode" visually distinct, not banner-on-broken-Berlin.** Drop vehicle layer entirely, swap live pulse for capability chip in pill, slightly larger stop dots (12pt vs 10pt) since stops are now the hero, persistent `.caption2` `.secondary` "Departures live · vehicle map coming soon", make the bottom sheet (departures) the primary surface. No banner-card chrome — chrome reads as "broken."

**(HIGH) H1 — CityPickerView (BerlinTransportMap/Views/CityPickerView.swift, 111 lines) needs rebuild.**
- Always-shown Done button (line 42) → broken first-launch lock; gate behind `dismissOnSelection`
- 2-col grid (lines 10-13) → switch to list rows so capability chip + "Near you" section fit
- Add: "Near you" section computed from `CLLocation` + `CityConfig.boundingBox`
- Add: capability chip per row — green `Live map` for Berlin, blue `Departures` for others
- Add: loading/empty/error states for the city-switch network handshake
- Fix: `interactiveDismissDisabled(true)` on first-launch presentation
- Add: search field appears at 6+ cities (it's at 10)

**(HIGH) H2 — Accent color contrast fails on more cities than plan claims.**
- Plan claims only Stuttgart `#ffc20e` + Dresden `#fdc500` need dark variants. False.
- Light bg AA failures: Stuttgart, Dresden, **Düsseldorf `#009fe3`** (codex flagged)
- Dark bg failures: Munich `#0d5c2e`, Frankfurt `#00428a`, Leipzig `#004e9e`, Berlin borderline
- Cologne `#ed1c24`/`#e2001a` fails AA for white text on accent
- Color-blind: palette collapses into red, blue, yellow clusters — color alone cannot identify city

Fix: add `accentColorOnLight: String` + `accentColorOnDark: String` to `CityConfig`. Use the on-light variant for pill text/check-icon over white surfaces; on-dark for over map tiles/dark mode. Yellow cities use `~#9e7a00` for text/icons; bright yellow only on the picker dot. Always pair color with the city name text — never color-alone.

**(HIGH) H3 — Favorites lack city identity (FavoriteRow.swift:78, FavoritesView.swift:77, FavoritesService.swift:61).** A favorited "Hauptbahnhof" is ambiguous between Berlin and Munich (both have one). FavoriteRow shows no city label. FavoritesService fetches departures via the *current* city service, which means Munich-favorited stops break when user is "in Berlin." Fix: see Eng review.

**(HIGH) H4 — Widget Berlin-hardcoded (ios/TransportWidget.swift:32-33,68,72,102,200,260,272-273,285-286).** "Configuration display name" reads Berlin Transport. Sample data is Alexanderplatz + Hauptbahnhof. Endpoint is `https://v6.vbb.transport.rest`. Munich user adds a Munich stop; widget polls VBB and silently shows wrong/no data. Fix: see Eng review.

**(MEDIUM) M1 — DESIGN.md Direction section (DESIGN.md:10) explicitly says "Berlin Transport Map is Berlin-only." That sentence is now false.** Codex says keep "Berliner Precision" name and treat other cities as additive supported networks. Subagent says rewrite to "Functional Precision." This is a TASTE DECISION (kind, not coverage) — see Final Gate.

**(MEDIUM) M2 — Trademark risk for transit authority logos and accent colors (CityConfig.swift:65,79,124,139,154,169 — accentColorHex per city).** None of MVG/HVV/RMV/KVB/VVS/VRR/DVB/LVB/VAG colors are licensed. Plan suggests showing logos in CityPicker rows; if shipped, exposes single-DMCA-pulls-the-SKU risk. Fix: use the accent color hex (functional, hard to claim trademark) but NEVER raster logos. Verify hex colors aren't trademarked color marks (Lufthansa-yellow precedent).

### Design Completion Summary

| Dimension | Score | Notes |
|-----------|-------|-------|
| Information hierarchy | 4/10 | Pill spec'd, not built; first-launch confirmation missing |
| Interaction states | 3/10 | 9+ unspecified states |
| Onboarding fidelity for non-Berlin | 2/10 | 11 hardcoded surfaces |
| Visual taxonomy of degradation | 3/10 | Banner approach is wrong; needs deliberate mode |
| CityPickerView completeness | 4/10 | Shipped but missing chips, states, dismiss-lock |
| Accent contrast | 4/10 | More failures than plan admits; tokens needed |
| Brand identity coherence | 5/10 | DESIGN.md still says "Berlin-only" |
| **Overall** | **3.5/10** | Same as before; minor progress on shipped picker |

### Eng Re-Review — Dual Voices

**Codex (eng, re-run):** Codex hit usage limit during this phase. **[codex-unavailable]** — proceeding with Claude subagent only for Eng. Reduces redundancy but loses dual-voice cross-check on architecture findings; treat single-voice findings with appropriate caution.

**Claude subagent (eng, re-run):** Foundation laid (CityConfig, CityManager, services accept city, picker exists) but five load-bearing components remain Berlin-pinned: EventsService, OfflineStopsDatabase, Widget, MapTilePreloader, Favorite model. The central `updateCity` call has a real race condition. Capability flags don't exist. Zero tests for the new abstraction. Score: **5/10**.

### Eng Dual Voices — Consensus Table

| Dimension | Claude subagent | Codex | Consensus |
|-----------|-----------------|-------|-----------|
| 1. Architecture sound? | NO (5 components Berlin-pinned) | UNAVAILABLE | NOT CONFIRMED — subagent-only |
| 2. Test coverage sufficient? | NO (zero new tests) | UNAVAILABLE | NOT CONFIRMED — subagent-only |
| 3. Performance risks addressed? | NO (no task cancellation) | UNAVAILABLE | NOT CONFIRMED — subagent-only |
| 4. Security threats covered? | YES (no new attack surface) | UNAVAILABLE | NOT CONFIRMED — subagent-only |
| 5. Error paths handled? | NO (city-switch races; transient vs unsupported) | UNAVAILABLE | NOT CONFIRMED — subagent-only |
| 6. Deployment risk manageable? | NO (6-9 days work, plan says 1 week) | UNAVAILABLE | NOT CONFIRMED — subagent-only |

**Consensus: 0/6 confirmed (codex unavailable). Single-voice findings flagged regardless — code-grounded with file:line refs.**

**Source:** subagent-only (codex usage limit reached).

### Eng Re-Review Findings (code-grounded, file:line)

#### CRITICAL / HIGH

**E1 (HIGH) — `ServiceContainer.updateCity()` forgets 5 city-aware components.**

`BerlinTransportMap/Services/ServiceContainer.swift:39-46` propagates city to `transportService`, `routeService`, `vehicleRadarService`. Missing:
- **`predictiveLoader`** retains stale Berlin stops/departures across switch (`PredictiveLoader.swift:22-23` — never cleared). User switches to Munich; predictive loader serves Berlin stops as "predicted next."
- **`OfflineStopsDatabase.shared`** is Berlin-pinned and never told. `TransportService.searchLocations` short-circuits to it for ALL cities (`TransportService.swift:99-103`) — Munich users get Berlin stops as offline matches.
- **`EventsService`** still hits `https://api.berlin.de/events/` regardless of city.
- **Widget App Group payload** doesn't carry city info.
- **`MapTilePreloader.preloadBerlinTiles()`** runs unconditionally at launch (`BerlinTransportMapApp.swift:36`).

Fix: extend `ServiceContainer.updateCity` to call `predictiveLoader.clearPreloadedData()`, `offlineDatabase.switchCity(city)`, `eventsService.clearCache()` (or just gate via capability flag), and `widgetCenter.reload()`.

**E2 (HIGH) — Concurrency race in city switch.**

`ServiceContainer.swift:39-46`: `cityManager.selectCity` and `transportService.updateCity` run synchronously on `@MainActor`, but `vehicleRadarService.updateCity` is dispatched in an unstructured `Task { await ... }`. A user switching city and triggering a radar fetch within ~1ms fetches from the **old** baseURL.

`TransportService.updateCity` mutates `baseURL` (line 7) while in-flight `URLSession.data(from:)` requests still reference the old URL — they complete and surface as stale results to the new city. None of the services hold task handles; no cancellation.

Fix: (a) make `ServiceContainer.updateCity` `async`; await the radar update before returning. (b) Each service tracks its in-flight `Task?` and cancels on city change.

**E3 (HIGH) — `OfflineStopsDatabase` blast radius is larger than the plan implies.**

`BerlinTransportMap/Services/OfflineStopsDatabase.swift`:
- Line 7: singleton (`static let shared`)
- Line 10, 13, 14: Berlin filenames hardcoded
- Lines 243-255: Berlin grid hardcoded (lat 52.34→52.68, lon 13.08→13.76)
- Line 277: VBB endpoint hardcoded inside `fetchStopsForArea`
- `loadIfNeeded()` takes no city parameter

`TransportService.swift:99-103` calls `searchLocations` which short-circuits to `OfflineStopsDatabase` first — ALL cities pass through Berlin's offline DB.

Migration plan for existing Berlin users: keep the existing `berlin_all_stops_cached.json` filename mapped to `cityId == "berlin"`; namespace new cities as `{cityId}_all_stops_cached.json`. Drop the bundled `berlin_all_stops.json` from non-Berlin first-launch fetches (use API for new cities).

Fix: (a) actor non-singleton keyed by cityId. (b) Per-city grid coordinates (each city has its own lat/lon bounding box from `CityConfig.boundingBox`). (c) Guard `searchLocations` short-circuit by cityId. (d) Bundle top-50 stops per city as `{cityId}_top_stops.json` for instant first-launch.

**E4 (HIGH) — Per-city capability flags must be two-layer.**

`CityConfig.swift:10-22` — no `supportsRadar`/`supportsEvents`/`supportsRoutes` fields. Plan calls for these as ship gates.

Pattern: check at **service entry** (don't fetch — return empty / throw `.unsupportedForCity`) AND at **UI render** (don't show radar layer / events card / route entry). Service-only is wrong (spinners still appear). UI-only is wrong (network call still fires). Two-layer is the only safe pattern.

Capability checks belong on `CityConfig` (explicit), not runtime-detected — empty radar response can be transient and would flicker the UI.

```swift
// Add to CityConfig
let supportsRadar: Bool      // true: berlin (validated). false: rest until matrix runs.
let supportsEvents: Bool     // true: berlin only
let supportsRoutes: Bool     // true: all (HAFAS endpoint shared)
```

**E5 (HIGH) — Widget Berlin-hardcoded across two extensions.**

- `DepartureWidget/DepartureWidget.swift:105` hardcodes `https://v6.vbb.transport.rest/stops/<id>/departures`
- `ios/TransportWidget.swift:32-33,68,72,102,200,260,272-273,285-286` is fully Berlin: Alexanderplatz/Hauptbahnhof samples, Berlin center, "Berlin Transport" config display name, `BvgProvider`, `VBB_API_AID` env var.

Munich user adds a Munich stop to favorites → widget polls VBB endpoint → silently shows wrong/no data.

Fix: extend `WidgetSavedStop` model to `{id, name, cityId, apiBaseURL}` so per-stop API resolution works (favorites can span cities — a single "current city" key is wrong). Question: is `ios/TransportWidget.swift` shipped or legacy? If legacy, delete; if shipped, gate behind capability flag.

#### MEDIUM

**E6 (MEDIUM) — `RouteService.updateCity` lacks task cancellation.**

`BerlinTransportMap/Services/RouteService.swift:19-21` swaps `baseURL` only. A user mid-route-plan who switches cities receives a stale Berlin journey resolved against the new VRR `baseURL` — wrong data or 404.

Fix: track current `Task?` in `RouteService`; cancel on `updateCity()`.

**E7 (MEDIUM) — `EventsService` Berlin-only — gate off, don't make city-aware.**

`BerlinTransportMap/Services/EventsService.swift:8` hardcodes `https://api.berlin.de/events/`. Triggered unconditionally from `TransportMapView.swift:1055`. Card renders at lines 444-454.

No equivalent API for Munich/Hamburg — don't try to make EventsService city-aware. Cleanest fix: gate the call site with `guard cityManager.currentCity.supportsEvents else { return }`. Clear `events = []` in the existing `onChange(cityManager.currentCity)` block (around `:349`).

**E8 (MEDIUM) — `Favorite` model migration has 3 corruption paths.**

`BerlinTransportMap/Models/Favorite.swift:5-25` — adding `var cityId: String?` is SwiftData-additive and safe (existing rows get nil, treat as Berlin).

But:
- (a) `FavoritesService.saveStopFavorite` deduplicates by `stopId` only (`FavoritesService.swift:25`). Munich and Berlin Hauptbahnhof have different IDs in practice, so collision risk is low — but a same-ID coincidence silently merges the favorite. Fix: predicate on `(stopId == X && cityId == Y)`.
- (b) `syncToWidget` writes `WidgetSavedStop {id, name}` (`FavoritesService.swift:70-73`, widget side `DepartureWidget.swift:13-16`). Widget polls first stop against `https://v6.vbb.transport.rest` regardless of where it came from. Fix: add `cityId` + `apiBaseURL` to `WidgetSavedStop`.
- (c) `CommuteAlertManager` deep links carry `stopId` only (around `:97-98`). Munich alert opens departures resolved against current city — wrong if user has since switched. Fix: add `?city=` query param to deep link, parse in `ContentView` deep link handler.

**E9 (MEDIUM) — API endpoint validation matrix should be a script, not XCTest.**

Manual curl scripted into `scripts/validate-city-endpoints.sh` running `/locations/nearby`, `/locations?query=`, `/stops/:id/departures`, `/radar`, `/trips/:id`, `/journeys` against Munich + Hamburg coordinates with shape checks (jq for `.movements | length > 0`, `.departures[0].when` exists). XCTest integration tests are overkill — they require network, CI flakiness will dominate.

The matrix output drives the `supports*` flag values directly.

**E10 (MEDIUM) — `TransportMapView.swift` is 1874 lines.**

Adding city pill + capability chip + degradation banner + city-switch loading state pushes past 2000. Already shows symptoms — `EventsCard` is internal at `:1082`.

Fix is mechanical not blocking: extract `MapHeaderPill`, `EventsCard`, `WelcomeOverlay` integration, the `onChange(cityManager)` data-clearing block to separate files. Acceptable to defer for v2.0 but adds cognitive overhead during multi-city wiring.

**E11 (MEDIUM) — Test coverage zero for multi-city.**

`Tests/` has 7 files, none for CityConfig/CityManager/multi-city wiring.

Minimum viable for v2.0:
- `CityConfigTests`: 10 cities have unique IDs, valid URLs, non-empty bounding boxes, valid hex colors, capability flags consistent with API matrix
- `CityManagerTests`: persists to UserDefaults, defaults to Berlin when key missing, restores saved id
- `ServiceContainerUpdateCityTests`: after `updateCity(.munich)`, all services have DB endpoint; race regression test
- `FavoriteCityIdMigrationTests`: nil cityId reads as Berlin; dedupe is per-(stopId, cityId)
- `OfflineStopsDatabaseCityTests`: Munich query doesn't return Berlin stops

~5 files, ~150 lines, half a day. Skip mocked HTTP — too brittle for community API.

`Tests/PredictiveLoaderTests.swift` will break when `PredictiveLoader` gains city awareness — re-run.

**E12 (MEDIUM-taste) — Bundle display name still "Berlin Transport" on home screen.**

`BerlinTransportMap.xcodeproj/project.pbxproj:638,677`: `PRODUCT_DISPLAY_NAME = "Berlin Transport"`. `PRODUCT_BUNDLE_IDENTIFIER = com.dautov.berlintransportmap` — must NOT change (ITMS-90054 destroys upgrade path).

The CEO re-review's "defer rename" decision (audit row 25) was premised on protecting **ASO equity for the App Store title**. But `PRODUCT_DISPLAY_NAME` is the **home-screen label**, separate from the ASC listing. A Munich user installs an app called "Berlin Transport" on their home screen, opens it, sees Munich data — that's a worse trust violation than ASO loss.

Recommendation (TASTE — surfaces at gate): change `PRODUCT_DISPLAY_NAME` to a city-neutral string (e.g., "Transit Map") while keeping ASC listing as "Berlin Transport Map" until non-Berlin downloads validate. Apple permits ASC App Name ≠ PRODUCT_DISPLAY_NAME (search "App Store Connect display name vs bundle display name" — ASC App Name is what shows in search results / on the listing page; PRODUCT_DISPLAY_NAME is the home-screen label, capped at 30 chars). They're independent.

Alternative if user wants to keep "Berlin Transport" home label: ship Munich-named alternate icon labeled "München Transit" via `CFBundleAlternateIcons` (alternate icons can have alternate names). Half-fix.

#### Cross-cutting risks not surfaced in plan

- Bundle file `berlin_all_stops.json` ships in every install (`OfflineStopsDatabase.swift:10`). Munich users still get a Berlin stop database in their app bundle — wasted storage and incorrect search results pre-`searchLocations` rewrite.
- `MapTilePreloader.preloadBerlinTiles()` runs unconditionally at launch — bandwidth waste for Munich-default user.
- No task cancellation anywhere across services. Every city switch races against in-flight requests.

### Eng Test Plan

`~/.gstack/projects/dautovri-berlin-realtime-map/feat-germany-expansion-test-plan-20260428-170430.md` (created below).

### Eng Completion Summary

| Dimension | Score | Notes |
|-----------|-------|-------|
| Architecture | 5/10 | CityManager wired, services accept city; 5 components still Berlin-pinned (Events, OfflineStopsDB, Widget, MapTilePreloader, Favorite); race in updateCity |
| Test coverage | 1/10 | Zero new tests; 5 files needed (~half day) |
| Performance | 5/10 | No task cancellation; preloader/tile-preload Berlin-pinned |
| Security | 8/10 | No new attack surface; trademark risk is a legal concern, not a code one |
| Error handling | 4/10 | City-switch races, transient-vs-unsupported radar conflation, deep-link city missing |
| Deployment risk | 4/10 | Plan timeline assumes 1 week; subagent estimates 6-9 days for the ship-blocking items alone |

### Cross-Phase Themes (re-run)

**Theme A: Capability flags + API matrix block ship.** Flagged in CEO (decisions 26-27) and Eng (E4, E9). Both phases independently. Highest-confidence ship gate.

**Theme B: 5 Berlin-pinned components remain.** Eng E1, E3, E5, E7, E8 + cross-cutting note. Plan listed 10 files for refactor; actual blast radius spans Widget, MapTilePreloader, Favorite, CommuteAlertManager, deep links, bundled stops file.

**Theme C: City context invisible to user.** Design C1 (no map pill) + Eng E1 (predictive loader stale data) + Design C2 (onboarding hardcoded). User has no way to know they're "in" Munich — and the system has no way to know what city favorites/widget/predictions reference.

**Theme D: Race conditions on city switch.** Eng E2 + E6. No task cancellation, mixed sync/async in updateCity. Symptom: user switches city, sees stale departures from old city for ~1s.

**Theme E: Trust violation on Munich first install.** CEO finding (single SKU pooled rating) + Design C2 (onboarding "fundamentally dishonest") + Eng E12 (home-screen "Berlin Transport" label). Three independent angles on the same UX honesty problem.


