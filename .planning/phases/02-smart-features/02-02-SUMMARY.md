---
phase: 02-smart-features
plan: 02
subsystem: favorites
tags: [favorites, persistence, ui, swiftdata]
requires: ["01-ui-ux-enhancements"]
provides: [favorite-stops, favorite-routes]
affects: ["02-04", "02-05"]
tech-stack:
  added: [SwiftData]
  patterns: [MVVM, data-persistence]
key-files:
  created: ["BerlinTransportMap/Models/Favorite.swift", "BerlinTransportMap/FavoritesService.swift", "BerlinTransportMap/FavoritesView.swift"]
  modified: ["BerlinTransportMap/TransportMapView.swift", "BerlinTransportMap/BerlinTransportMapApp.swift"]
decisions: []
duration: 10
completed: 2026-01-25
---

# Phase 2 Plan 2: Favorites System for Stops and Routes

**One-liner:** Added SwiftData-based favorites system allowing users to save and quickly access favorite stops and routes.

## Objective

Allow users to save frequently used stops and routes for quick access, improving navigation efficiency.

## Implementation

### Tasks Completed

1. **Core Data Model** - Created SwiftData @Model Favorite with properties for stops/routes, including encoded route data.

2. **Favorites Service** - Implemented FavoritesService with full CRUD operations using SwiftData ModelContext.

3. **Favorites UI** - Built FavoritesView with list display, selection handling, and delete functionality; integrated floating favorites button and sheet in TransportMapView.

### Key Changes

- **Favorite.swift**: SwiftData model for persistent favorites storage
- **FavoritesService.swift**: Service layer for favorites management
- **FavoritesView.swift**: UI for browsing and selecting favorites
- **TransportMapView.swift**: Added favorites button and sheet integration
- **BerlinTransportMapApp.swift**: Configured SwiftData model container

## Verification

Favorites can be viewed in list, selected to navigate to stops or display routes on map, and deleted via swipe actions.

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

Favorites system ready for integration with journey history (02-04) and recommendations (02-05).