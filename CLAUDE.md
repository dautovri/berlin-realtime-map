
## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health

## Design System

The project uses **Berliner Precision** — see `DESIGN.md` for the full spec.

Key rules for all SwiftUI work:
- Status colors: `#00A550` on time, `#E8641A` delayed, `#C41E3A` cancelled, `#6B4E9E` service change, `#8A8A8E` stale
- Departure times and counts: always `.monospacedDigit()`
- Station names: always `.fontDesign(.rounded)`
- Spacing: 8pt base grid (8 / 16 / 24 / 32 / 48)
- Animations: respect `@Environment(\.accessibilityReduceMotion)`
- Line badges: authentic transit-authority colors only (VBB/BVG for Berlin, each city's own palette elsewhere) — never approximate
- No hardcoded font sizes except the hero ETA (42pt bold monospaced in departure sheets)

## Multi-City Architecture

The app supports multiple German cities via a city-config system. Berlin is the default and only fully validated city; other cities are gated by capability flags until each city's API endpoint matrix is validated.

Key types:
- `CityConfig` (`BerlinTransportMap/Models/CityConfig.swift`) — per-city transit authority, API base URL, map region, accent color, supported transport products, and capability flags (`supportsRadar`, `supportsEvents`, `supportsRoutes`).
- `CityManager` (`BerlinTransportMap/Services/CityManager.swift`) — `@MainActor @Observable` singleton holding the active `CityConfig`. Persists selection via `UserDefaults` under key `selectedCityId`. Defaults to `.berlin`.
- `ServiceContainer` — owns the per-city service instances (`TransportService`, `VehicleRadarService`, `RouteService`, etc.) and exposes an async `updateCity(_:)` that rebuilds them when the user switches cities.
- `Favorite` and `CommuteAlert` carry a `cityId` field so per-city saved data is scoped correctly. A migration backfills missing `cityId` to `"berlin"` for legacy entries.

Rules for multi-city work:
- Always read the active city via `CityManager.currentCity` — never hardcode `.berlin` outside the default fallback.
- Before exposing a city-specific feature in the UI, check the relevant capability flag (`supportsRadar`, `supportsEvents`, `supportsRoutes`). If false, hide the affordance — do not just disable it. The "Live" badge in `TransportMapView` and the radar widget gate on `supportsRadar`.
- New cities go in `CityConfig.allCities` with `supportsRadar: false` until validated by `scripts/validate-city-endpoints.sh`.
- When adding a service that hits a city-scoped endpoint, take `CityConfig` (or the API base URL) as a constructor argument and let `ServiceContainer.updateCity` rebuild it on city switch — do not read `CityManager` directly inside the service.
- Tests for city-aware code live in `Tests/CityConfigTests.swift`, `Tests/CityManagerTests.swift`, `Tests/FavoriteCityIdMigrationTests.swift`, `Tests/OfflineStopsDatabaseCityTests.swift`, and `Tests/ServiceContainerUpdateCityTests.swift`.