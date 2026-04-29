# Berlin Transport Map 🚇

**Track Berlin's U-Bahn, S-Bahn, trams, and buses in real-time — with multi-city support across Germany**

[![App Store](https://img.shields.io/badge/App%20Store-Download-blue?logo=apple)](https://apps.apple.com/de/app/berlin-transport-map/id6757723208?l=en-GB)
[![Platform](https://img.shields.io/badge/Platform-iOS%2026.0%2B-blue?logo=apple)](https://www.apple.com/ios)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)
[![Stars](https://img.shields.io/github/stars/dautovri/berlin-realtime-map?style=flat)](https://github.com/dautovri/berlin-realtime-map/stargazers)
[![License](https://img.shields.io/github/license/dautovri/berlin-realtime-map?style=flat)](LICENSE)

See where your train, bus, or tram is right now on a live map. No account required, no tracking—just real-time German transit data on an interactive map. Berlin is the default city; additional German cities can be selected from the in-app city picker.

**Repo topics:** iOS · Swift · SwiftUI · MapKit · Berlin · Germany · Public Transport · Realtime · VBB · HAFAS

## ✨ Features

- 📍 **Live Vehicle Tracking** - Watch U-Bahn, S-Bahn, trams, and buses move in real-time
- 🗺️ **Interactive Map** - Pan and zoom with smooth MapKit performance to find nearby stops
- ⏱️ **Real-Time Departures** - Tap any stop to see upcoming departures with live delay information
- 🚏 **Stop Search** - Find stations and stops instantly
- 🌍 **Multi-City (Germany)** - Berlin by default, with a city picker for additional German cities. Per-city capability flags gate features (radar, events, routes) so the UI only shows what each transit authority's API supports.
- 📱 **Native iOS & tvOS** - Built with SwiftUI and MapKit for a fast, modern experience; also runs on Apple TV
- 🎯 **First-Launch Onboarding** - Welcome overlay explains live tracking and prompts for location with context
- 🔒 **Privacy First** - No account required, no tracking, no third-party analytics
- 🌐 **Multi-Language** - Available in English, German, and French

## Demo video

GitHub READMEs don’t reliably embed playable video inline, but a hosted MP4 link works well.


https://github.com/user-attachments/assets/24c63c55-b6df-4db9-b696-d4b377d96b81

## Requirements

- iOS 26.0+
- Xcode 16.0+

## Architecture

Simple single-target iOS app:

- **App code**: `BerlinTransportMap/`
- **Dependencies**: Swift Package dependencies managed by Xcode (TripKit)
- **Build Settings**: Stored in `BerlinTransportMap.xcodeproj` (no separate xcconfig files)

## Libraries used

- **SwiftUI** (Apple) — UI framework
- **MapKit** (Apple) — map rendering, annotations, polylines
- **TripKit** (third-party) — public transport client used to fetch Berlin/VBB real-time data
	- Repo: https://github.com/alexander-albers/tripkit
	- Data backend: VBB HAFAS (see also https://github.com/public-transport/hafas-client)

## Development

### Building
```bash
# Open in Xcode
open BerlinTransportMap.xcworkspace

# Build from terminal
xcodebuild -workspace BerlinTransportMap.xcworkspace -scheme BerlinTransportMap build
```

### Testing
```bash
bundle exec fastlane ios test
```

### Deployment
```bash
# TestFlight
bundle exec fastlane ios beta

# App Store
bundle exec fastlane ios release
```

### Release checklist

- Confirm `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `BerlinTransportMap.xcodeproj` are correct
- Run tests (`bundle exec fastlane ios test`)
- Run `bundle exec fastlane ios beta` (TestFlight) before `ios release`

## Data Source

Uses HAFAS-based public-transport APIs for real-time data. Berlin uses the [VBB HAFAS API](https://github.com/public-transport/hafas-client) (Berlin-Brandenburg). Additional German cities are configured per-city in `BerlinTransportMap/Models/CityConfig.swift` with their own API base URL, supported transport products, and capability flags.

## License

MIT License - see [LICENSE](LICENSE)

## Author

**Ruslan Dautov** - [GitHub](https://github.com/dautovri)

---

## Support

For bugs and feature requests:

- https://github.com/dautovri/berlin-realtime-map/issues/new

When reporting a problem, please include:
- iPhone/iPad model
- iOS version
- What you expected vs what happened
- Screenshot/screen recording (if possible)

## Privacy

Privacy policy:

- https://gist.github.com/dautovri/2ca5f7b5b4b3789056c5dadbf1f60966
