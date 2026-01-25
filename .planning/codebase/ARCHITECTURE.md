# Architecture

**Analysis Date:** 2025-01-25

## Pattern Overview

**Overall:** MVVM (Model-View-ViewModel) with service layer

**Key Characteristics:**
- SwiftUI-based iOS application with reactive UI updates
- Service-oriented architecture for data fetching
- Observable objects for state management
- Async/await for asynchronous operations
- Actor-based concurrency for API services

## Layers

**UI Layer:**
- Purpose: Handles user interface and user interactions
- Location: `BerlinTransportMap/TransportMapView.swift`, `BerlinTransportMap/ContentView.swift`
- Contains: SwiftUI views, view modifiers, extensions
- Depends on: Service Layer, Model Layer
- Used by: Application entry point

**Service Layer:**
- Purpose: Manages external data sources and business logic
- Location: `BerlinTransportMap/TransportService.swift`, `BerlinTransportMap/VehicleRadarService.swift`, `BerlinTransportMap/LocationManager.swift`
- Contains: API clients, location services, data processing
- Depends on: External APIs (TripKit, VBB REST API), CoreLocation
- Used by: UI Layer

**Model Layer:**
- Purpose: Defines data structures and business entities
- Location: Embedded in service files (TransportStop, Vehicle, etc.)
- Contains: Structs for transport data, enums for products
- Depends on: None
- Used by: Service Layer, UI Layer

## Data Flow

**Map Interaction Flow:**

1. User moves map → `TransportMapView.onMapCameraChange` triggers
2. Calls `loadStopsForRegion()` → `TransportService.queryNearbyStops()`
3. Calls `loadVehicles()` → `VehicleRadarService.fetchVehicles()`
4. Updates `@State` arrays → SwiftUI re-renders map annotations

**Stop Details Flow:**

1. User taps stop marker → sets `selectedStop`
2. Shows `RESTDeparturesSheet` → calls `loadDepartures()`
3. `VehicleRadarService.fetchDepartures()` fetches data
4. Displays departures in sheet

**Vehicle Info Flow:**

1. User taps vehicle marker → sets `selectedVehicle`
2. Shows `VehicleInfoSheet` → optional route loading
3. `VehicleRadarService.fetchTripRoute()` gets polyline
4. Displays route on map

**State Management:**
- `@State` properties in `TransportMapView` for UI state
- `@Observable` classes for services
- Manual state updates with async operations

## Key Abstractions

**TransportService:**
- Purpose: Handles static transport data (stops, departures) via TripKit
- Examples: `queryNearbyStops()`, `queryDepartures()`
- Pattern: Observable class with async methods

**VehicleRadarService:**
- Purpose: Fetches real-time vehicle positions and departures via REST API
- Examples: `fetchVehicles()`, `fetchDepartures()`, `fetchTripRoute()`
- Pattern: Actor for thread-safe API calls

**LocationManager:**
- Purpose: Manages user location permissions and updates
- Examples: `requestPermission()`, location updates
- Pattern: Observable NSObject subclass conforming to CLLocationManagerDelegate

## Entry Points

**BerlinTransportMapApp:**
- Location: `BerlinTransportMap/BerlinTransportMapApp.swift`
- Triggers: App launch
- Responsibilities: Sets up main window with ContentView

**ContentView:**
- Location: `BerlinTransportMap/ContentView.swift`
- Triggers: App initialization
- Responsibilities: Wraps TransportMapView

**TransportMapView:**
- Location: `BerlinTransportMap/TransportMapView.swift`
- Triggers: User interactions with map
- Responsibilities: Main view controller, state management, data loading

## Error Handling

**Strategy:** Try-catch with user-friendly error messages

**Patterns:**
- Async methods throw custom errors (TransportError, VehicleError)
- Errors displayed in UI overlay
- Retry buttons for network failures
- Graceful degradation (empty states)

## Cross-Cutting Concerns

**Logging:** Minimal, uses print() for location errors

**Validation:** Input validation for API parameters

**Authentication:** Uses public API keys for TripKit, no user auth

---

*Architecture analysis: 2025-01-25*