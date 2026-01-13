# Berlin Transport Map 🚇

Real-time public transport tracker for Berlin. See where your train, bus, or tram is right now on a live map.

[![App Store](https://img.shields.io/badge/App%20Store-Download-blue?logo=apple)](https://apps.apple.com/app/id6753555139)

## Features

- 📍 **Live Vehicle Tracking** - Watch U-Bahn, S-Bahn, trams, and buses move in real-time on the map
- 🗺️ **Interactive Map** - Pan and zoom around Berlin to find nearby stops
- ⏱️ **Real-Time Departures** - Tap any stop to see upcoming departures with live delay info
- 📱 **Native iOS** - Built with SwiftUI and MapKit for a fast, modern experience
- 🔒 **Privacy First** - No account required, no tracking, no third-party analytics. Location (if granted) is used to show nearby transit and isn't stored by the app.

## Demo video

GitHub READMEs don’t reliably embed playable video inline, but a hosted MP4 link works well.

- Watch the demo (MP4): [video.MP4](docs/screenshots/video.MP4)

Tip: the easiest way to get a stable GitHub-hosted URL is to upload the video to a GitHub Issue (or Release), then copy the resulting `https://github.com/<owner>/<repo>/assets/...` link.

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