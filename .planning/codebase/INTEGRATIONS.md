# External Integrations

**Analysis Date:** 2026-01-25

## APIs & External Services

**Public Transport Data:**
- VBB REST API - Real-time vehicle positions, departures, and trip routes
  - SDK/Client: Direct HTTP requests in `BerlinTransportMap/VehicleRadarService.swift`
  - Auth: None required (public API)
  - Base URL: https://v6.vbb.transport.rest
  - Endpoints used: /radar, /stops/{id}/departures, /trips/{id}

**HAFAS Transport API:**
- VBB HAFAS API - Station search, nearby stops, and departures
  - SDK/Client: TripKit library in `BerlinTransportMap/TransportService.swift`
  - Auth: API key hardcoded (public key: 1Rxs112shyHLatUX4fofnmdxK)
  - Provider: BvgProvider from TripKit

## Data Storage

**Databases:**
- Not applicable - No local database storage

**File Storage:**
- Not applicable - No file storage requirements

**Caching:**
- Not applicable - No caching layer implemented

## Authentication & Identity

**Auth Provider:**
- Not applicable - No user authentication required

## Monitoring & Observability

**Error Tracking:**
- Not applicable - No error tracking service

**Logs:**
- Console logging only - No external logging service

## CI/CD & Deployment

**Hosting:**
- App Store - iOS App Store distribution

**CI Pipeline:**
- Fastlane - Automated build and deployment scripts
  - Configuration: `fastlane/` directory
  - Commands: `bundle exec fastlane ios test`, `bundle exec fastlane ios beta`, `bundle exec fastlane ios release`

## Environment Configuration

**Required env vars:**
- APP_STORE_CONNECT_API_KEY_JSON_PATH=./fastlane/AppStoreConnect_API_Key.json
- APP_STORE_CONNECT_KEY_ID=REPLACE_ME_KEY_ID
- APP_STORE_CONNECT_ISSUER_ID=REPLACE_ME_ISSUER_ID
- APP_STORE_CONNECT_KEY_FILEPATH=./fastlane/AuthKey_REPLACE_ME.p8
- TEAM_ID=REPLACE_ME_TEAM_ID
- EXPORT_TEAM_ID=REPLACE_ME_TEAM_ID

**Secrets location:**
- App Store Connect credentials stored in `fastlane/` directory

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

---

*Integration audit: 2026-01-25*