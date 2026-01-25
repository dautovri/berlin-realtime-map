---
phase: 02-smart-features
plan: 03
subsystem: predictions
tags: [predictions, historical-data, machine-learning]
requires: ["02-01"]
provides: [arrival-predictions]
affects: ["02-04", "02-05"]
tech-stack:
  added: []
  patterns: [data-analysis, predictive-modeling]
key-files:
  created: ["BerlinTransportMap/Models/HistoricalData.swift", "BerlinTransportMap/PredictionService.swift"]
  modified: ["BerlinTransportMap/TransportMapView.swift"]
decisions: []
duration: 2
completed: 2026-01-25
---

# Phase 2 Plan 3: Predictive Arrival Times Based on Historical Data

**One-liner:** Implemented predictive arrival times using historical delay patterns displayed alongside realtime data.

## Objective

Provide users with estimated arrival times using historical patterns to improve journey planning accuracy.

## Implementation

### Tasks Completed

1. **Historical Data Model** - Created HistoricalData struct with day/week/time patterns, UserDefaults storage for learning from past arrivals.

2. **Prediction Service** - Implemented PredictionService calculating average delays for similar conditions (line, stop, day, hour).

3. **UI Integration** - Added predictions to departure details showing predicted vs realtime arrival times in stop sheets.

### Key Changes

- **HistoricalData.swift**: Data model and storage for historical arrivals
- **PredictionService.swift**: Algorithm for predicting delays based on patterns
- **TransportMapView.swift**: Integration showing predictions in departure lists

## Verification

Stop departure details display predicted arrival times based on historical data for the line and conditions.

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

Prediction system provides data foundation for journey history analysis (02-04).