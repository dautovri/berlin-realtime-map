---
phase: 02-smart-features
plan: 01
subsystem: routing
tags: [routing, ui, api, map]
requires: ["01-ui-ux-enhancements"]
provides: [route-planning, map-display]
affects: ["02-03", "02-04", "02-05"]
tech-stack:
  added: [TripKit]
  patterns: [MVVM, async-await]
key-files:
  created: ["BerlinTransportMap/RoutePlannerView.swift", "BerlinTransportMap/RouteService.swift"]
  modified: ["BerlinTransportMap/TransportMapView.swift"]
decisions: []
duration: 5
completed: 2026-01-25
---

# Phase 2 Plan 1: Route Planning with Transport Mode Selection

**One-liner:** Implemented route planning UI and backend integration displaying routes on map using TripKit VBB API.

## Objective

Enable users to plan efficient journeys by selecting start/end points and preferred transport modes, integrating with VBB routing APIs.

## Implementation

### Tasks Completed

1. **Route Planner UI** - Created SwiftUI view with start/end stop text fields, transport mode picker (Train/Bus/Subway/Tram), and plan route button.

2. **VBB Routing Integration** - Implemented RouteService using TripKit library with BvgProvider for route planning, handling transport mode conversion and error management.

3. **Map Route Display** - Added route overlay on map using MapPolyline, integrated RoutePlannerView as sheet, added floating route button for access.

### Key Changes

- **RoutePlannerView.swift**: New UI component for route input and planning
- **RouteService.swift**: Service layer for VBB API integration with TripKit
- **TransportMapView.swift**: Added route display, planner sheet integration, and UI controls

## Verification

Route planning tested through UI: select stops, choose mode, plan route displays on map with blue polyline overlay.

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

Route planning foundation established for predictive features (02-03) and journey history (02-04).