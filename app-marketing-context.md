## App Overview
- **App Name (live):** Berlin Transit Map: Live BVG
- **App ID (Apple):** 6757723208
- **App ID (Google Play):** N/A
- **Category:** Travel
- **Secondary Category:** Navigation
- **Platform:** iOS
- **Price Model:** Free with optional tip jar
- **Launch Date:** Live on App Store
- **Current Version (live):** 1.5
- **Next Version (in flight):** 1.7 — multi-city foundation, Berlin-led identity preserved
- **Future rename to "German Transit Map":** v1.9+ aspirational; gated by /autoplan pass-3 row 25 — defer until non-Berlin downloads ≥ 30/mo for 60 days

## Naming policy (v1.7-v1.8)

The pass-3 /autoplan decision (2026-04-29) defers the "German Transit Map" rename
until distribution data validates non-Berlin demand. v1.7 ships the multi-city
*foundation* under capability gates (only Berlin shows live vehicle map; other
cities show live departures + stop search). The App Store listing keeps
"Berlin Transit Map: Live BVG" as the title. v1.8's distribution sprint runs
ASO + Apple Search Ads + App Store Featured against this Berlin-led identity.

The v2.0 metadata sketch below (German Transit Map, all-cities messaging) is
preserved as the v1.9+ target. Do not push it to ASC until the rename gate fires.

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

## v1.7 ASO State (current — Berlin-led, multi-city foundation)

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
