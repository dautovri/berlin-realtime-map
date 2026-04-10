# Design System — Berliner Precision

**Berlin Transport Map v1.5+**  
Established: 2026-04-09

---

## Direction

**Berliner Precision.** Every competitor (Transit App, DB Navigator, Moovit, Citymapper) uses generic international design language. Berlin Transport Map is Berlin-only. The design leans into that: the clarity and graphic confidence of Berlin's Bauhaus heritage, expressed through a transit information system.

The result is a UI that feels like it belongs on a BVG platform — not a startup's growth dashboard.

---

## Color

### Primary

| Token | Hex | Usage |
|-------|-----|-------|
| `primaryBlue` | `#115D97` | Interactive elements, selected states, U-Bahn badges. Existing brand color — keep. |
| `backgroundPrimary` | System `.background` | Main map background, sheet background. |
| `backgroundSecondary` | System `.secondarySystemBackground` | Card surfaces, grouped cells. |

### Semantic Status

Four colors. Every departure state maps to exactly one of them. No other colors for status.

| Token | Hex | Status | Usage |
|-------|-----|--------|-------|
| `statusOnTime` | `#00A550` | On time | VBB brand green. Used for on-time departures and the Live badge pulse. |
| `statusDelayed` | `#E8641A` | Delayed | Amber. Shown on delay badges (+N min). |
| `statusCancelled` | `#C41E3A` | Cancelled | Crimson. Used for strikethrough text + "Cancelled" label. |
| `statusServiceChange` | `#6B4E9E` | Service change / diversion | Purple, borrowed from DB Navigator. Used when a line is rerouted. |
| `statusStale` | `#8A8A8E` | Stale data | System gray. The "Stale" badge in departure sheets when data is >30s old. |

### Line Badges

Authentic VBB/BVG colors. Never approximate — these are the exact colors commuters recognize.

| Line type | Color source |
|-----------|-------------|
| U-Bahn | BVG U-line colors (U1 green, U2 red, U3 olive, U5 dark blue, U6 purple, U7 orange, U8 blue, U9 orange-red) |
| S-Bahn | S-Bahn Berlin green (#006F35) |
| Regional (RE/RB) | Red (#C0392B) |
| Tram (M/T lines) | Dark red (#8B0000) |
| Bus | Purple (#6B4E9E) |
| Ferry | Teal (#008B8B) |

Badge shape: rounded rectangle, `cornerRadius` = half of badge height.  
Badge text: SF Pro Bold, white, tight tracking.

---

## Typography

All text uses SF Pro (system default). No custom fonts.

| Role | Modifier | Notes |
|------|----------|-------|
| Body, labels | Default `.body` / `.caption` | System sizes, Dynamic Type enabled everywhere |
| Departure times, counts | `.monospacedDigit()` | Keeps columns stable as digits change. Apply to all time strings. |
| Station names | `.fontDesign(.rounded)` | Softer and more map-like than default SF Pro. |
| Hero ETA | `.font(.system(size: 42, weight: .bold, design: .monospaced))` | One place only: the top of the departure sheet. Inspired by Departures Boards. |

**Dynamic Type:** All views must support all Dynamic Type sizes. No hardcoded `font(.system(size: N))` except for the Hero ETA. Use `.minimumScaleFactor(0.8)` on the hero if needed.

---

## Spacing

**Base unit: 8pt.** All padding, margins, and gaps are multiples of 8.

| Token | Value | Common usage |
|-------|-------|-------------|
| `space1` | 8pt | Icon-to-label gap, tight insets |
| `space2` | 16pt | Card padding, row horizontal padding |
| `space3` | 24pt | Section spacing |
| `space4` | 32pt | Sheet top padding, large gaps |
| `space6` | 48pt | Full-bleed hero sections |

---

## Motion

Minimal-functional. Animation exists to communicate state change, not to entertain.

| Interaction | Animation |
|------------|-----------|
| Welcome overlay appear/dismiss | `.easeInOut(duration: 0.4)` on `.opacity` (already implemented in `ContentView`) |
| Welcome overlay page transitions | Slide, 0.3s |
| Sheet present/dismiss | System default sheet animation |
| Live badge pulse | 3s repeating scale pulse on the green dot — communicates that data is actually live |
| Departure sheet data refresh | Cross-fade on content update, 0.2s |

**Reduce Motion:** All slide/scale animations must respect `@Environment(\.accessibilityReduceMotion)`. Substitute instant transitions or simple opacity fades.

---

## Patterns

### Hero ETA

The primary information on a departure sheet. One massive number at the top.

```swift
Text("3 min")
    .font(.system(size: 42, weight: .bold, design: .monospaced))
    .monospacedDigit()
    .foregroundStyle(statusColor) // green/amber/crimson
```

Place it above the departure list, not inside the list.

### Live Badge

A small animated indicator that confirms data is fresh.

```swift
Circle()
    .fill(Color(hex: "#00A550"))
    .frame(width: 8, height: 8)
    .scaleEffect(isPulsing ? 1.3 : 1.0)
    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
```

Shown in the sheet header when `lastFetchAge < 30s`. Switch to the gray `statusStale` dot and stop animation when data ages out.

### Departure Row

```
[Line badge]  [Destination]           [+N min]
[U5]          Hönow                   +2 min   → amber
[S3]          Erkner                  On time  → green (or no label)
[M6]          Marzahn                 +60 min  → amber
[RE1]         Frankfurt (Oder)        Cancelled → crimson strikethrough
```

- Time in `.monospacedDigit()` so columns hold.
- Delay badge only when delayed > 0. "On time" is a good state — show it in green or omit the badge.
- Cancelled: red label, destination and scheduled time in strikethrough.

### Stop Favorites

Station name in `.fontDesign(.rounded)`. Type label ("Stop" / "Route") in `.caption` with secondary foreground.

---

## Accessibility

- All interactive elements: minimum 44×44pt touch target.
- All text: Dynamic Type from `.caption2` through `.accessibilityExtraExtraExtraLarge`.
- Color is never the only indicator of status — always pair with a text label or icon.
- VoiceOver: every departure row reads as "[Line] to [destination], [status]".
- Line badges: `.accessibilityLabel("\(lineNumber) line")`.

---

## What This System Is Not

- No custom fonts (Berliner Grotesk, etc.) — adds complexity, complicates App Store review, risks fallback ugliness. SF Pro is the right call on Apple platforms.
- No glassmorphism, gradients, or decorative illustration. The map is the hero visual.
- No dark-mode-only design decisions. The color system must work in both light and dark.
- No pixel-perfect fixed layouts. Everything scales with Dynamic Type and all device sizes.
