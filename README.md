# Berlin Transport Map 🚇

Real-time public transport tracker for Berlin. See where your train, bus, or tram is right now on a live map.

[![App Store](https://img.shields.io/badge/App%20Store-Download-blue?logo=apple)](https://apps.apple.com/app/id6753555139)
[![Stars](https://img.shields.io/github/stars/dautovri/berlin-realtime-map?style=flat)](https://github.com/dautovri/berlin-realtime-map/stargazers)
[![Issues](https://img.shields.io/github/issues/dautovri/berlin-realtime-map?style=flat)](https://github.com/dautovri/berlin-realtime-map/issues)
[![License](https://img.shields.io/github/license/dautovri/berlin-realtime-map?style=flat)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/dautovri/berlin-realtime-map?style=flat)](https://github.com/dautovri/berlin-realtime-map/commits/main)

**Repo topics:** iOS · Swift · SwiftUI · MapKit · Berlin · Public Transport · Realtime · VBB · HAFAS

## Features

- 📍 **Live Vehicle Tracking** - Watch U-Bahn, S-Bahn, trams, and buses move in real-time on the map
- 🗺️ **Interactive Map** - Pan and zoom around Berlin to find nearby stops
- ⏱️ **Real-Time Departures** - Tap any stop to see upcoming departures with live delay info
- 📱 **Native iOS** - Built with SwiftUI and MapKit for a fast, modern experience
- 🔒 **Privacy First** - No account required, no tracking, no third-party analytics. Location (if granted) is used to show nearby transit and isn't stored by the app.

## Demo video

GitHub READMEs don’t reliably embed playable video inline, but a hosted MP4 link works well.


https://github.com/user-attachments/assets/24c63c55-b6df-4db9-b696-d4b377d96b81

## Requirements

- iOS 17.0+
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

Uses the [VBB HAFAS API](https://github.com/public-transport/hafas-client) for real-time Berlin-Brandenburg public transport data.

## License

MIT License - see [LICENSE](LICENSE)

## Author

**Ruslan Dautov** - [GitHub](https://github.com/dautovri)
