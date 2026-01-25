# Technology Stack

**Analysis Date:** 2026-01-25

## Languages

**Primary:**
- Swift 6.0 - iOS application development

**Secondary:**
- Not applicable

## Runtime

**Environment:**
- iOS 26.0+ - Native iOS app runtime

**Package Manager:**
- Swift Package Manager - Dependency management via Xcode
- Lockfile: `BerlinTransportMap.xcworkspace/xcshareddata/swiftpm/Package.resolved`

## Frameworks

**Core:**
- SwiftUI - User interface framework
- MapKit - Map rendering and location services

**Testing:**
- Not detected

**Build/Dev:**
- Xcode 16.0+ - IDE and build system

## Key Dependencies

**Critical:**
- TripKit 1.17.0 - Public transport client library for Berlin/VBB data
- SwiftyJSON 5.0.2 - JSON parsing library
- SWXMLHash 6.0.0 - XML parsing library
- GzipSwift 5.2.0 - Gzip compression library

**Infrastructure:**
- Not applicable

## Configuration

**Environment:**
- Xcode project configuration in `BerlinTransportMap.xcodeproj`
- Build settings managed within Xcode

**Build:**
- No separate config files - configuration stored in Xcode project

## Platform Requirements

**Development:**
- macOS with Xcode 16.0+
- iOS Simulator or physical iOS device

**Production:**
- iOS 26.0+ devices

---

*Stack analysis: 2026-01-25*