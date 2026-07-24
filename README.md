# Berlin Transport Map

A real-time transit map for German cities. See U-Bahn, S-Bahn, trams, buses, and ferries move live on a map — no account, no tracking, no ads. Open source and built with SwiftUI.

Most transit apps show you a countdown. This one shows you the actual vehicle, right now, on the map. Berlin is fully supported with live radar; additional German cities have departures and routing.

- **Live radar.** Vehicles update every 5 seconds on the map. Berlin has full radar support; other cities show departures and routes.
- **4,775 Berlin stops** in an offline database — search works instantly, even without a network connection.
- **10 German cities.** Berlin, Hamburg, Munich, Cologne, Frankfurt, Leipzig, and more — each with its own transit authority API.
- **Zero tracking.** No analytics SDKs, no accounts, no third-party data collection. Location is used only to center the map.
- **Open source.** MIT licensed. The entire codebase is here.

```
Tap any stop → see live departures with delay info → tap a vehicle → watch it move
```

https://github.com/user-attachments/assets/24c63c55-b6df-4db9-b696-d4b377d96b81

---

## Get it

[Download on the App Store](https://apps.apple.com/de/app/berlin-transport-map/id6757723208?l=en-GB) — free, with an optional tip jar.

---

## Contents

- [Development](#development)
- [Architecture](#architecture)
- [Data source](#data-source)
- [Support](#support)
- [Privacy](#privacy)

---

## Development

Requires iOS 26.0+ and Xcode 16.0+.

### Build

```bash
open BerlinTransportMap.xcworkspace
```

Or from the terminal:

```bash
xcodebuild -workspace BerlinTransportMap.xcworkspace -scheme BerlinTransportMap build
```

### Test

```bash
bundle exec fastlane ios test
```

### Deploy

```bash
# TestFlight
bundle exec fastlane ios beta

# App Store
bundle exec fastlane ios release
```

## Architecture

Single-target SwiftUI app. Key directories:

- `BerlinTransportMap/` — all app code
- `BerlinTransportMap/Models/CityConfig.swift` — per-city transit authority, API base URL, map region, and capability flags
- `BerlinTransportMap/Services/` — transport, radar, and route services, rebuilt on city switch
- Dependencies managed via Swift Package Manager (TripKit)

## Data source

Real-time data comes from HAFAS-based public transport APIs. Berlin uses the [VBB HAFAS API](https://github.com/public-transport/hafas-client); other cities use [DB transport.rest](https://v6.db.transport.rest). The HAFAS client library is [TripKit](https://github.com/alexander-albers/tripkit).

## Support

File bugs and feature requests: [open an issue](https://github.com/dautovri/berlin-realtime-map/issues/new).

When reporting a problem, include your device model, iOS version, what you expected vs. what happened, and a screenshot if possible.

## Privacy

[Privacy policy](https://gist.github.com/dautovri/2ca5f7b5b4b3789056c5dadbf1f60966) — no data collected, no accounts, location used only to center the map.

## License

MIT — see [LICENSE](LICENSE).

## Author

[Ruslan Dautov](https://github.com/dautovri)
