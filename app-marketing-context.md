## App Overview
- **App Name (live):** German Transit Map  *(renamed from "Berlin Transit Map: Live BVG" in v1.8 on 2026-05-04 — pass-3 rename gate overridden by founder)*
- **App ID (Apple):** 6757723208
- **App ID (Google Play):** N/A
- **Category:** Travel
- **Secondary Category:** Navigation
- **Platform:** iOS
- **Price Model:** Free with optional tip jar
- **Launch Date:** Live on App Store
- **Current Version (live):** 1.7 (multi-city foundation, Berlin-led identity)
- **Next Version (in flight):** 1.8 — German Transit Map rename, AFTER_APPROVAL auto-release; submitted 2026-05-04
- **Localized names:** German Transit Map (en), Deutsche Nahverkehr Karte (de), Mapa Tránsito Alemania (es), Carte Transit Allemagne (fr), ドイツ交通マップ (ja)

## Naming policy (v1.8 — rename live)

Pass-3 /autoplan deferred the rename until non-Berlin downloads ≥ 30/mo for 60
days. The founder overrode that gate on 2026-05-04 (immediately after v1.7
shipped) on the basis that the multi-city foundation is now real and the
"Berlin" framing actively misleads non-Berlin users. v1.8 carries the rename to
"German Transit Map" plus all-cities messaging across en-US / de-DE / es-ES /
fr-FR / ja.

Risk acknowledged at decision time: existing Berlin-led ASO authority on
"BVG"/"Berlin" terms gets diluted. Mitigation: the v1.8 distribution sprint
(ASO + Apple Search Ads + App Store Featured) runs against the new German-led
identity instead of validating demand under the old name first. Re-evaluate
ranking impact 30 days post-release.

## Value Proposition
- **Problem:** Public transit riders in Germany want to know where their U-Bahn, tram, or bus actually is right now — not just what the schedule says. Most apps show timetables, not live vehicle positions.
- **Target Audience:** Residents of Berlin, München, Hamburg, Frankfurt, Köln, and Stuttgart; daily commuters, tourists, and transit fans who want live vehicle tracking on a real interactive map.
- **Unique Differentiator:** Real-time vehicle positions on a MapKit map across all major German cities, not just departure boards. Live delay data, multi-city coverage (BVG, MVG, HVV, RMV, KVB, VVS), no account, no tracking.
- **Elevator Pitch:** Watch trains, trams, and buses move live on a real map — across Germany's biggest cities. Tap any stop for departures with live delays.

## Supported Cities & Transit Authorities
| City | Authority | Transit Types |
|------|-----------|---------------|
| Berlin | BVG / VBB | U-Bahn, S-Bahn, Tram, Bus, Ferry |
| München | MVG | U-Bahn, S-Bahn, Tram, Bus |
| Hamburg | HVV | U-Bahn, S-Bahn, Bus, Ferry |
| Frankfurt | RMV | U-Bahn, S-Bahn, Tram, Bus |
| Köln | KVB | Stadtbahn, S-Bahn, Bus |
| Stuttgart | VVS | Stadtbahn, S-Bahn, Bus |

## Competitors
| App | App ID | Strengths | Weaknesses |
|-----|--------|-----------|------------|
| BVG Jelbi | BVG official | Ticketing, authority data | No live vehicle map, heavyweight, Berlin only |
| DB Navigator | Deutsche Bahn | National coverage | Complex UI, no live vehicle map |
| Transit | 493867874 | Real-time tracking, multi-city | Subscription model, North American focus |
| MVG Fahrinfo | MVG official | Deep MVG integration | München only, no live map |
| Google Maps | N/A | Familiar interface, broad coverage | Not transit-specific, privacy concerns |

## v1.8 ASO State (current — German Transit Map rename, in review)

The actual v1.8 metadata pushed to ASC is in `metadata/app-info/{locale}.json`
(name + subtitle, cross-version) and `metadata/version/1.8/{locale}.json`
(description + keywords + promotionalText + whatsNew, version-specific).
Verified pre-push: name ≤ 30 chars per locale, subtitle ≤ 30 chars, keywords
≤ 100 UTF-8 bytes (en-US 90B / de-DE 91B / es-ES 88B / fr-FR 87B / ja 87B),
promo ≤ 170 chars (en 147 / de 142 / es 149 / fr 160 / ja 68), description
≤ 4000 chars per locale.

Notable: v1.8 keyword field drops VVS (Stuttgart hidden) and replaces with
LVB/Leipzig — keywords now match cities the user can actually pick. The seven
working cities listed in the description are Berlin, München, Hamburg,
Frankfurt, Köln, Leipzig, Nürnberg.

## v1.7 ASO State (now superseded — Berlin-led, multi-city foundation)

### Live (v1.5, all locales)
- **Title (en-US):** Berlin Transit Map: Live BVG (28 chars)
- **Subtitle (en-US):** Live S-Bahn, U-Bahn, Tram & Bus (30 chars) — updated v1.7
- **Title (de-DE):** Berlin Nahverkehr Live (22 chars)
- **Title (es-ES):** Mapa Tránsito Berlín: BVG (25 chars)
- **Title (fr-FR):** Berlin Transit: Carte Live BVG (30 chars)
- **Title (ja):** ベルリン交通マップ: BVGライブ (16 chars)

### v1.7 metadata changes (in `metadata/version/1.7/`)
- en-US subtitle changed from "U-Bahn S-Bahn Tram & Bus Times" → "Live S-Bahn, U-Bahn, Tram & Bus" (leads with differentiator "Live"; 30 chars)
- All 5 locales: keyword field trimmed under 100 UTF-8 bytes (es/fr/ja were silently truncated by ASC pre-v1.7)
- Added münchen/hamburg (and equivalents per locale) to keyword field — primes city-name searches without committing to rename
- Removed redundant terms (transport, tracker, bvg) that already appear in title/subtitle and were wasting bytes
- whatsNew rewritten for v1.7 multi-city foundation announcement, Berlin-led tone

### v1.9+ aspirational (German Transit Map rename — DO NOT push until rename gate fires)

### en-US
- **Title:** German Transit Map (18 chars)
- **Subtitle:** Live S-Bahn U-Bahn Tram & Bus (30 chars)
- **Keywords:** BVG,MVG,HVV,RMV,KVB,VVS,VBB,München,Hamburg,Frankfurt,Köln,Stuttgart,departures,delay,realtime (96 bytes)
- **Promotional Text:** Now covering Berlin, München, Hamburg, Frankfurt, Köln & Stuttgart. Live transit tracking for all major German cities.

### de-DE
- **Title:** Deutsche Nahverkehr Karte (25 chars)
- **Subtitle:** Echtzeit S-Bahn U-Bahn & Bus (29 chars)
- **Keywords:** öpnv,bvg,mvg,hvv,rmv,kvb,vvs,vbb,berlin,münchen,hamburg,frankfurt,köln,stuttgart,fahrplan (92 bytes)

### es-ES
- **Title:** Mapa Tránsito Alemania (22 chars)
- **Subtitle:** Tren Tranvía y Bus en Vivo (26 chars)
- **Keywords:** bvg,mvg,hvv,rmv,kvb,vvs,vbb,múnich,hamburgo,fráncfort,colonia,stuttgart,metro,salida,retraso (94 bytes)

### fr-FR
- **Title:** Carte Transit Allemagne (23 chars)
- **Subtitle:** S-Bahn U-Bahn Tram & Bus Live (30 chars)
- **Keywords:** bvg,mvg,hvv,rmv,kvb,vvs,vbb,berlin,munich,hambourg,francfort,cologne,stuttgart,métro,départ (93 bytes)

### ja
- **Title:** ドイツ交通マップ (8 chars)
- **Subtitle:** 全都市のリアルタイム時刻表 (12 chars)
- **Keywords:** BVG,MVG,HVV,RMV,KVB,VVS,VBB,ベルリン,ミュンヘン,ケルン,出発,遅延,駅,電車 (91 bytes)

### Keyword Strategy Notes
- Terms already in title/subtitle are auto-indexed by Apple, so NOT repeated in keyword field: german, transit, map, live, s-bahn, u-bahn, tram, bus
- All 6 transit authority codes (BVG, MVG, HVV, RMV, KVB, VVS) included in every locale
- City names localized per locale (e.g., München/Múnich/Munich)
- Complementary high-value terms added per locale: departures, delay, realtime (en-US); öpnv, fahrplan (de-DE); etc.

## Goals
1. Rank for "German transit map", "live departures Germany", and city-specific terms across all 6 cities
2. Convert tourists and expats in any major German city through strong map-first screenshots
3. Build a repeat-use base of daily commuters across all supported cities
4. Expand from Berlin-only to pan-German positioning as a differentiated multi-city live tracker

## Resources
- **Budget:** Solo / lean indie budget
- **Team:** Solo developer
- **Tools:** Xcode, App Store Connect, asc CLI, TripKit (HAFAS)
- **Constraints:** Dependent on per-city HAFAS API availability

## Markets
- **Primary:** Germany — Berlin, München, Hamburg, Frankfurt, Köln, Stuttgart
- **Secondary:** English-speaking tourists and expats in Germany; French-speaking visitors
- **Languages:** English, German, Spanish, French, Japanese

## Screenshot Strategy

### First screen (hero)
City selector showing all 6 supported cities with a live map behind it. Message: **"All of Germany's transit, live."**

### Screen 2
Live map view with multiple colored vehicle dots moving across a city map — showing the new city selector. Message: **"Watch trains & buses move in real time."**

### Screen 3
Stop detail popover open on a real station showing departures with live countdown timers and delay badges. Message: **"Tap any stop. See live departures."**

### Screen 4
Split view showing 2-3 different cities side by side. Message: **"Berlin. München. Hamburg. And more."**

### Screen 5
Privacy / no-account emphasis. Message: **"No account. No tracking. Just transit."**

### Logo note
App icon asset in `BerlinTransportMap/AppIcon.icon`. If marketing artwork beyond the App Store icon is needed, export a 1024x1024 PNG from the icon catalog.

## App Store Description (en-US)

### Short description (first 3 lines — shown before "more")
Track public transit across Germany's biggest cities — live on the map, every second.

German Transit Map shows you where your train, tram, or bus actually is right now. Not just schedules — real vehicles, moving in real time. Now covering Berlin, München, Hamburg, Frankfurt, Köln, and Stuttgart.

### Full description
(See ASC version localization for full text — updated for v2.0 with all-cities messaging.)

### Promotional text (170 chars max)
Now covering Berlin, München, Hamburg, Frankfurt, Köln & Stuttgart. Live transit tracking for all major German cities.

### What's New (v2.0)
German Transit Map 2.0 — now covering all major German cities!

NEW CITIES: München (MVG), Hamburg (HVV), Frankfurt (RMV), Köln (KVB), Stuttgart (VVS)

IMPROVEMENTS: Redesigned city selector, faster map rendering, Liquid Glass app icon, departure widget with live data.

## Version History
| Version | Key Changes |
|---------|------------|
| 1.0 | Initial release — Berlin only |
| 1.1 | Bug fixes |
| 1.2 | Performance improvements |
| 1.3 | macOS support added |
| 1.4 | Additional improvements |
| 1.5 | Live departures onboarding, Liquid Glass icon, departure widget |
| 2.0 | Multi-city expansion: München, Hamburg, Frankfurt, Köln, Stuttgart (PREPARING) |
