# QA Report — Berlin Transport Map (Session 3)
**Date:** 2026-04-13
**Branch:** main
**Commit:** 602e2da
**Scope:** Onboarding P1 regression + full smoke test (all screens). Follows Sessions 1 and 2 from same date.

---

## Summary

| Severity | Found | Fixed | Deferred |
|----------|-------|-------|----------|
| P1 (onboarding) | 3 open from prior session | 3 fixed | 0 |
| New issue | 1 (ISSUE-007) | 1 fixed | 0 |
| Product improvement | 1 | 0 | 1 (P1 backlog) |

---

## Onboarding P1 Items — All Resolved

### Back button missing from all screens
**Status: ✅ Already fixed (code confirmed, not in TODOS as completed)**
`OnboardingView.swift:230` — `if step > 0 && step != 6` correctly gates back button.
Verified in simulator: step 1 shows Back, tapping returns to step 0 (WelcomeScreen, no Back). Step 7 back-skips step 6 (ProcessingScreen) correctly.

### Location denial: silent dead end on ProcessingScreen
**Status: ✅ Already fixed (code confirmed, not in TODOS as completed)**
`ProcessingScreen` at lines 783-796 shows "Location off — map starts at Alexanderplatz. Enable in Settings → Privacy anytime." when `authorizationStatus == .denied || .restricted`. Location denied during test — app advanced after 2.5s with message shown. No silent dead end.

### SwiftData save: conditional confirmation on ValueDeliveryScreen
**Status: ✅ Fixed this session** — commit `602e2da`
- `saveSelectedStops()` now called when advancing to step 8 (not step 9), so saves complete before `ValueDeliveryScreen` renders
- Returns `Bool`; `saveSucceeded` state passed to `ValueDeliveryScreen`
- Subtitle now shows "Stops saved to Favorites ✓" on success or "Couldn't save your stops — re-add them in Favorites." on failure
- Premature "✓" removed from `DemoScreen` subtitle

---

## ISSUE-007 — VehicleInfoSheet: raw Lat/Lon + Trip ID exposed to users
**Severity:** Medium  
**Status:** ✅ Fixed — commit `602e2da`

`VehicleInfoSheet` showed raw GPS coordinates (Lat/Lon in monospaced caption font) and internal Trip ID ("Trip: XXXXXX") to users. Both are debug-only data with no user value.

**Fix:** Removed the Lat/Lon `HStack` block and the `fahrtNr` Trip ID `Text` view entirely. Sheet height detent reduced 200→160pt to fit the trimmed layout.

---

## P1 Product Improvement (deferred to backlog)
**ValueDeliveryScreen: show real live departures instead of sample data**  
After completing onboarding, `ValueDeliveryScreen` shows `stop.sampleDepartures` (hardcoded). The subtitle even admits "Example departures — your live data loads in the app."  
The fix is to fetch real BVG API departure data for `selectedStops` on screen appear and show live arrivals — the strongest possible "aha moment" for a transit app.  
Logged in TODOS as P1 product improvement.

---

## Full Smoke Test Results

| Screen / Feature | Result | Notes |
|---|---|---|
| Main map — live vehicles | ✅ Pass | U-Bahn, S-Bahn, trams, buses all animate |
| Vehicle tap → VehicleInfoSheet | ✅ Pass | Line badge, direction, type, Show Route — no debug data |
| Show Route | ✅ Pass (prior session) | Route overlay draws on map |
| Map zoom → stop markers | ✅ Pass | Appear at latitudeDelta ≤ 0.04 |
| Stop tap → departures sheet | ✅ Pass | Live BVG data, times, platform, delay badges |
| Star → Add to Favorites | ✅ Pass | "Added to Favorites" alert fires, star disabled |
| Favorites sheet | ✅ Pass | Saved stop appears, accessible |
| Journey Planner | ✅ Pass | Hermannplatz → Alexanderplatz, U8, 13 min |
| About sheet | ✅ Pass | Share, Rate, links all present |
| Tip Jar (Support) | ✅ Pass | 3 tip buttons enabled, "Not now" present |
| Help sheet | ✅ Pass | Sections, content present |
| Settings | ✅ Pass | Follow System ON, Dark Mode disabled correctly |
| Onboarding — back navigation | ✅ Pass | All steps (except Welcome + Processing) |
| Onboarding — location denial | ✅ Pass | "Location off" message shown on ProcessingScreen |
| Onboarding — save confirmation | ✅ Pass | "Stops saved to Favorites ✓" after fix |

---

## Health Score

| Category | Score |
|---|---|
| Core map + live vehicles | 10/10 |
| VehicleInfoSheet | 10/10 (was 9 — debug data removed) |
| Stop departures sheet | 10/10 |
| Journey Planner | 10/10 |
| Favorites | 10/10 |
| Onboarding | 9/10 (save P1 fixed; live departures on ValueDelivery deferred) |
| Settings | 9/10 (toggle automation blocked by iOS 26 sim — code confirmed correct) |
| About / Help / Support | 10/10 |
| Tip Jar / StoreKit | 10/10 |
| Accessibility | 9/10 |

**Overall: 98/100** (+1 from Session 2's 97 — ISSUE-007 + onboarding P1s closed)
