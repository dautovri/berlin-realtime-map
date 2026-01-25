# Codebase Concerns

**Analysis Date:** 2026-01-25

## Tech Debt

**TransportMapView.swift (783 lines):**
- Issue: Massive view file handling map display, data loading, UI state, and multiple sheets
- Files: `BerlinTransportMap/TransportMapView.swift`
- Impact: Violates single responsibility, hard to maintain, test, or modify
- Fix approach: Extract into separate view models (MapViewModel, StopsViewModel, VehiclesViewModel), split supporting views into dedicated files

**VehicleRadarService.swift (313 lines):**
- Issue: Service class contains all related models and response structs
- Files: `BerlinTransportMap/VehicleRadarService.swift`
- Impact: Models should be in separate files, service focused only on networking
- Fix approach: Move all model structs to `Models/` directory, keep only service logic

**TransportService.swift (299 lines):**
- Issue: Similar to above, models mixed with service logic
- Files: `BerlinTransportMap/TransportService.swift`
- Impact: Poor separation of concerns, hard to reuse models
- Fix approach: Extract models to separate files, consider using @unchecked Sendable safely or remove it

## Known Bugs

**No known bugs identified:**
- No TODO/FIXME comments found in codebase
- Error handling appears basic but functional
- Files: N/A

## Security Considerations

**Hardcoded API Keys:**
- Risk: API authorization keys are hardcoded in source code
- Files: `BerlinTransportMap/TransportService.swift` (lines 10-14)
- Current mitigation: Marked as "public keys used by the BVG app", but still exposed in git
- Recommendations: Move to secure configuration (environment variables, keychain), consider proper API authentication

**Unsafe Concurrency:**
- Risk: @unchecked Sendable and nonisolated(unsafe) usage bypasses Swift's safety checks
- Files: `BerlinTransportMap/TransportService.swift` (lines 7, 11)
- Current mitigation: None apparent
- Recommendations: Properly implement Sendable conformance or use actors for thread safety

## Performance Bottlenecks

**Continuous API Polling:**
- Problem: Vehicles load every 5 seconds when live updating enabled
- Files: `BerlinTransportMap/TransportMapView.swift` (lines 264-271)
- Cause: No backoff, rate limiting, or smart updates
- Improvement path: Implement WebSocket/real-time updates if available, add exponential backoff, cache responses

**No Request Throttling:**
- Problem: Stop loading has 1-second throttle, but no global rate limiting
- Files: `BerlinTransportMap/TransportMapView.swift` (lines 307-337)
- Cause: Simple time-based check, no queue or debouncing
- Improvement path: Implement proper request deduplication and debouncing

## Fragile Areas

**TransportStop.vbbStopId Parsing:**
- Files: `BerlinTransportMap/TransportStop.swift` (lines 139-161)
- Why fragile: Complex string parsing of HAFAS IDs with fallbacks
- Safe modification: Add comprehensive unit tests for various ID formats before changes
- Test coverage: None apparent

**Date Decoding in VehicleRadarService:**
- Files: `BerlinTransportMap/VehicleRadarService.swift` (lines 48-64)
- Why fragile: Custom ISO8601 parsing with multiple fallbacks, repeated in multiple methods
- Safe modification: Extract to reusable DateFormatter utility
- Test coverage: None apparent

## Scaling Limits

**API Dependencies:**
- Current capacity: Depends on VBB REST API and TripKit library limits
- Limit: Unknown API rate limits, potential blocking if exceeded
- Scaling path: Implement caching, request batching, and fallback to cached data

## Dependencies at Risk

**TripKit Library:**
- Risk: Third-party iOS framework, potential maintenance issues
- Impact: Core stop search functionality would break
- Migration plan: Monitor for updates, consider VBB REST API alternative for stops

**VBB REST API:**
- Risk: External API dependency, potential changes or deprecation
- Impact: Vehicle radar and departures would fail
- Migration plan: Implement fallback providers, cache offline data

## Missing Critical Features

**Offline Support:**
- Problem: No offline functionality, app unusable without network
- Blocks: Use in areas with poor connectivity

**Error Recovery:**
- Problem: Basic error display, no retry logic beyond manual button
- Blocks: Poor user experience during API outages

## Test Coverage Gaps

**No Test Suite:**
- What's not tested: All business logic, API calls, parsing, UI behavior
- Files: No test files found, only .xctestplan configuration
- Risk: Bugs in parsing, API changes, or logic errors undetected
- Priority: High - implement unit tests for models, services, and view models

**Model Parsing:**
- What's not tested: JSON decoding for Vehicle, RESTDeparture, TransportStop
- Files: `BerlinTransportMap/VehicleRadarService.swift`, `BerlinTransportMap/TransportService.swift`
- Risk: API schema changes break silently
- Priority: High

---

*Concerns audit: 2026-01-25*