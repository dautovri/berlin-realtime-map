# Technology Stack

**Analysis Date:** 2026-01-25

## Languages

**Primary:**
- Swift - iOS application code in `BerlinTransportMap/`

**Secondary:**
- Python 3 - Build automation scripts in `scripts/` and root

## Runtime

**Environment:**
- iOS 17+ / macOS - Swift runtime environment

**Package Manager:**
- Swift Package Manager - Dependency management
- Lockfile: Not applicable (Xcode managed)

## Frameworks

**Core:**
- SwiftUI - Declarative UI framework for app interface
- MapKit - Apple Maps integration for transport visualization
- CoreLocation - GPS and location services

**Testing:**
- XCTest - Apple's testing framework (configured but not implemented)

**Build/Dev:**
- Xcode 15+ - IDE and build system

## Key Dependencies

**Critical:**
- TripKit 1.17.0 - Public transport client library for Berlin/VBB data

**Infrastructure:**
- Not applicable

## Configuration

**Environment:**
- Environment variables in `.env` for Fastlane/App Store Connect
- Key configs required: APP_STORE_CONNECT_API_KEY_JSON_PATH, TEAM_ID

**Build:**
- Xcode project file: `BerlinTransportMap.xcodeproj`
- Test plan: `BerlinTransportMap.xctestplan`

## Platform Requirements

**Development:**
- macOS with Xcode 15+
- iOS Simulator or physical device

**Production:**
- iOS 17.0+ deployment target

---

*Stack analysis: 2026-01-25*