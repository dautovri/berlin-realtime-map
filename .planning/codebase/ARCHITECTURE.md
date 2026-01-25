# Architecture

**Analysis Date:** 2026-01-25

## Pattern Overview

**Overall:** MVVM with SwiftUI
- SwiftUI declarative views with @State and @Observable classes
- Services handle business logic and API communication
- Clean separation between UI state and data fetching

**Key Characteristics:**
- Asynchronous data fetching with async/await
- Actor-based services for thread safety
- Observable state management
- MapKit integration for location display
- REST API integration for real-time data

## Layers

**Presentation Layer:**
- Purpose: UI rendering and user interaction
- Location: `BerlinTransportMap/TransportMapView.swift`, `BerlinTransportMap/ContentView.swift`
- Contains: SwiftUI views, map annotations, sheets
- Depends on: Service layer, Location layer
- Used by: App entry point

**Service Layer:**
- Purpose: Data fetching and business logic
- Location: `BerlinTransportMap/TransportService.swift`, `BerlinTransportMap/VehicleRadarService.swift`
- Contains: API clients, data models, error handling
- Depends on: External APIs (TripKit, VBB REST)
- Used by: Presentation layer

**Location Layer:**
- Purpose: User location tracking
- Location: `BerlinTransportMap/LocationManager.swift`
- Contains: CLLocationManager wrapper
- Depends on: CoreLocation framework
- Used by: Presentation layer

## Data Flow

**Stop Loading:**

1. Map camera changes trigger `loadStopsForRegion()`
2. TransportService queries TripKit API for nearby stops
3. Stops displayed as annotations on map

**Vehicle Loading:**

1. Timer or user action triggers `loadVehicles()`
2. VehicleRadarService fetches from VBB REST API
3. Vehicles displayed as moving annotations

**Departure Loading:**

1. User taps stop annotation
2. VehicleRadarService fetches departures from VBB REST API
3. Departures shown in sheet view

**State Management:**
- @State for local view state (loading, selected items)
- @Observable classes for shared services
- Task-based async operations

## Key Abstractions

**TransportStop:**
- Purpose: Represents public transport stops
- Examples: `BerlinTransportMap/TransportService.swift`
- Pattern: Identifiable, Hashable struct with computed properties

**Vehicle:**
- Purpose: Represents moving public transport vehicles
- Examples: `BerlinTransportMap/VehicleRadarService.swift`
- Pattern: Decodable struct with computed location coordinate

**RESTDeparture:**
- Purpose: Represents upcoming departures from stops
- Examples: `BerlinTransportMap/VehicleRadarService.swift`
- Pattern: Decodable struct with computed display time

## Entry Points

**BerlinTransportMapApp:**
- Location: `BerlinTransportMap/BerlinTransportMapApp.swift`
- Triggers: App launch
- Responsibilities: Root window setup

**ContentView:**
- Location: `BerlinTransportMap/ContentView.swift`
- Triggers: App initialization
- Responsibilities: Main view container

**TransportMapView:**
- Location: `BerlinTransportMap/TransportMapView.swift`
- Triggers: ContentView rendering
- Responsibilities: Map display, data loading, user interaction

## Error Handling

**Strategy:** Async throws with user-friendly error messages
- Network errors caught and mapped to localized strings
- UI displays error banners with retry options
- Cancellation support for task cleanup

**Patterns:**
- `try await` in view methods
- Error state stored in @State
- Conditional error UI rendering

## Cross-Cutting Concerns

**Logging:** Console print statements for location errors

**Validation:** Input validation in API parameter construction

**Authentication:** None required - public APIs used

---

*Architecture analysis: 2026-01-25*