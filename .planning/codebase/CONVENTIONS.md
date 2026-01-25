# Coding Conventions

**Analysis Date:** 2026-01-25

## Naming Patterns

**Files:**
- PascalCase for structs and classes: `TransportMapView.swift`, `TransportService.swift`
- Descriptive names: `VehicleRadarService.swift`, `LocationManager.swift`

**Functions:**
- camelCase: `loadStopsForRegion()`, `fetchVehicles()`
- Descriptive with action verbs: `requestPermission()`, `centerOnUserLocation()`

**Variables/Properties:**
- camelCase: `locationManager`, `transportService`
- Boolean prefixes: `isLoading`, `hasInitializedLocation`
- Arrays with plural: `stops`, `vehicles`

**Types:**
- PascalCase: `TransportStop`, `VehicleError`
- Protocol conformances in extensions

**Constants:**
- static let with camelCase: `berlinCenter`, `nearbySpan`
- UPPER_CASE for file constants: Not detected

## Code Style

**Formatting:**
- Xcode default formatting observed
- Consistent indentation (4 spaces in code)
- No linting/formatting config detected

**Linting:**
- No linting configuration detected (.swiftlint.yml not found)
- Manual code review appears consistent

## Import Organization

**Order:**
1. Foundation and system frameworks first: `import Foundation`, `import SwiftUI`
2. Third-party libraries: `import TripKit`
3. Alphabetical within groups

**Path Aliases:**
- Not detected (Xcode project uses relative paths)

## Error Handling

**Patterns:**
- Custom error enums with LocalizedError: `TransportError`, `VehicleError`
- Async throws: `func fetchVehicles(...) async throws -> [Vehicle]`
- Guard statements for validation
- Try/catch with specific error types

**Logging:**
- Print statements for debugging: `print("Location error: \(error.localizedDescription)")`
- No structured logging framework detected

## Comments

**When to Comment:**
- MARK comments for code organization: `// MARK: - Supporting Views`
- Doc comments for public APIs: `/// Service for fetching real-time vehicle positions`
- Inline comments for complex logic

**Documentation:**
- Triple-slash comments for services and key functions
- No JSDoc/TSDoc equivalent (Swift uses ///)

## Function Design

**Size:**
- Main view functions can be large (TransportMapView has 783 lines)
- Service functions are focused and smaller
- Private helpers extracted where needed

**Parameters:**
- Labelled parameters: `north: Double, west: Double`
- Default values for optional behavior: `duration: Int = 30`

**Return Values:**
- Optional for fallible operations: `TransportStop?`
- Arrays for collections: `[TransportStop]`

## Module Design

**Exports:**
- Public structs and functions
- Private implementation details

**Extensions:**
- Used for protocol conformances: `extension LocationManager: CLLocationManagerDelegate`
- Color extensions for hex support

## Async Programming

**Patterns:**
- async/await for network calls
- Task for UI operations: `Task { await loadDepartures(for: stop) }`
- Actor isolation for services: `actor VehicleRadarService`
- @MainActor for UI classes

**Concurrency:**
- @Observable for reactive state
- Task cancellation with checkCancellation()

## Architecture Patterns

**MVVM:**
- Observable view models: `@Observable final class TransportService`
- Views bind to state: `@State private var transportService = TransportService()`

**Services:**
- Actor for thread-safe services: `actor VehicleRadarService`
- Singleton-like initialization with dependency injection

## Code Organization

**File Structure:**
- One main type per file
- Supporting types in same file with MARK sections
- Extensions at file end

**Access Control:**
- Private for implementation details
- Internal for module visibility (default)
- Public for API surfaces