<!-- /autoplan restore point: /Users/rd/.gstack/projects/dautovri-berlin-realtime-map/main-autoplan-restore-20260413-000353.md -->

# Berlin Transport Map — v1.6 Submission + v1.7 Cleanup

**Branch:** main | **Date:** 2026-04-13 | **Version:** 1.6 (build 12)

---

## Context

v1.6 (build 12) is fully built and on main. Four PRs were merged since v1.5:
- PR #1: First-launch welcome overlay (3-screen, shipped in v1.5)
- PR #2: SwiftUI polish, Live badge redesign, v1.5 screenshots (3 EN + 3 DE)
- PR #3: ASO metadata gaps fixed
- PR #4: 12-screen OnboardingView (personalisation flow, SwiftData stop-picker demo, tip jar) — replaces WelcomeOverlayView in ContentView. Also includes: Next.js screenshots generator + Puppeteer export, 6-slide EN + DE screenshots uploaded to ASC (IPHONE_67).

**What's done for v1.6:**
- OnboardingView (1295 lines) live in ContentView
- 6 screenshots per locale uploaded to ASC via `asc screenshots upload --device-type IPHONE_67 --replace`
- Version bumped to 1.6, build 12

**What's missing before live users see v1.6:**
1. CHANGELOG.md has no v1.6 entry
2. Binary (IPA) not yet uploaded to ASC — needs Xcode Archive + Distribute
3. App not submitted for App Store review

**Dead code introduced in v1.6:**
- `BerlinTransportMap/Views/WelcomeOverlayView.swift` (326 lines) still exists but is no longer referenced anywhere. ContentView uses `OnboardingView` exclusively. Safe to delete.

**Known bugs to fix in v1.7 (from TODOS.md):**
- Stop-tap async race: rapid stop taps can show wrong departure data
- `vehicleFetchCount` cap: review prompt fires indefinitely past count 20 (fix: cap at 21)

---

## Plan A: v1.6 App Store Submission (Immediate)

### Step 1: Add CHANGELOG v1.6 entry

Add an entry to CHANGELOG.md for v1.6 covering:
- 12-screen personalised onboarding flow (goal picker, tinder-cards, stop-picker demo, tip jar)
- App Store screenshots regenerated: 6-slide layout EN + DE via Next.js generator

### Step 2: Archive + Upload Binary

Open Xcode → Product → Archive with the BerlinTransportMap scheme, Any iOS Device. Then upload via Organizer → Distribute → App Store Connect.

Binary version: 1.6 (build 12).

### Step 3: Submit for App Store Review

After binary processes on ASC (~15-30 min), submit v1.6 for review. Encryption compliance: No.

---

## Plan B: v1.7 Cleanup Sprint

### Bug 1: Stop-tap async race
**File:** `BerlinTransportMap/Views/TransportMapView.swift` ~line 519
**Fix:** In `loadDepartures(for stop:)`, add:
`guard selectedStop?.id == stop.id else { isLoadingDepartures = false; return }`
immediately before writing `restDepartures`.

### Bug 2: vehicleFetchCount unbounded
**File:** `BerlinTransportMap/Views/TransportMapView.swift` ~line 651
**Fix:** `if vehicleFetchCount < 21 { vehicleFetchCount += 1 }` — cap at 21, NOT 20.
At 20 the `== 20` check fires. Cap at 21 means it fires once and is never reached again.

### Cleanup 1: Delete dead WelcomeOverlayView.swift
**File:** `BerlinTransportMap/Views/WelcomeOverlayView.swift` (326 lines)
OnboardingView replaced WelcomeOverlayView in ContentView.swift (PR #4). No other Swift
file imports or references WelcomeOverlayView. Safe to delete.

### Cleanup 2: Update TODOS.md — mark WelcomeOverlay items obsolete
Several TODOS.md entries reference WelcomeOverlayView (ScrollView wrapper, isRequesting guard,
FeatureRow @ScaledMetric, version key, staggered animations, already-granted location state).
These are now obsolete since WelcomeOverlayView is dead code. Mark or remove them.

---

## Goals

- v1.6 live in App Store with the new onboarding and fresh screenshots.
- v1.7 ships clean: 2 genuine bug fixes, dead code deleted, TODOS.md tidy.
- Zero regression on iOS.

---

## Plan A: v1.6 Submission — UPDATED (CEO review corrections)

### Step 0 (NEW — blocking): QA SwiftData stop-picker save on device

Before submitting, verify the OnboardingView stop-picker demo actually persists to SwiftData:
1. Fresh install (or delete app + reinstall)
2. Run through onboarding to the stop-picker screen
3. Select 1-2 stops, tap "Continue"
4. Complete onboarding
5. Open Favorites — verify saved stops appear
6. Kill app, relaunch — verify stops persist

If stops don't persist: OSLog will show `FavoritesService` errors. Fix before submission.

### Step 0.5 (NEW — recommended): 48-hour TestFlight beta

The new 12-screen onboarding is a major UX change. Before App Store submission, distribute
a build via TestFlight (internal testers only — zero additional cost once the binary is
uploaded). Watch for crashes and unexpected exits from the onboarding flow.

Steps: Archive → Organizer → Distribute → TestFlight Internal Testing → invite 3-5 testers.
After 48 hours with no critical issues, proceed to Step 3 (App Store submission).

---

## Out of Scope

- OnboardingView A/B testing (no analytics infra yet)
- VBB API resilience / fallback (elevated to P2 in TODOS.md — existential risk, next sprint)
- Portfolio consolidation MyStop Berlin + Berlin Transport Map (bring to /office-hours)
- Unit test harness (no test framework in this repo yet — P3)
- Route replay implementation (needs Favorite model changes — separate sprint)

---

## Open Questions

- **`hasSeenWelcome` rename** — Renaming to `hasSeenOnboardingV2` would re-show the new 12-screen flow to all existing users. The new onboarding surfaces stop-picker and tip jar that existing users haven't seen. Could be good re-engagement OR could be annoying. [TASTE DECISION — surfaced at approval gate]
- WelcomeOverlayView.swift: delete completely (it's in git history if needed).
- VBB API fallback: escalate from P3 → P2 in TODOS.md (next sprint prototype GTFS-RT fallback).

---

## Phase 1: CEO Review — SELECTIVE EXPANSION [subagent-only — Codex usage limit Apr 16]

### 0A: Premise Challenge

| Premise | Status | Notes |
|---------|--------|-------|
| OnboardingView replaced WelcomeOverlayView | ✅ Valid | ContentView.swift confirmed. WelcomeOverlayView.swift is dead code. |
| Screenshots already uploaded to ASC | ✅ Valid | 6 EN + 6 DE uploaded via `asc screenshots upload --device-type IPHONE_67 --replace` |
| Binary not yet uploaded | ✅ Valid | No upload history; requires Xcode Archive |
| CHANGELOG has no v1.6 entry | ✅ Valid | CHANGELOG.md ends at [1.5] |
| SwiftData stop-picker save works | ⚠️ UNVERIFIED | PLAN.md open question confirmed by CEO subagent — no device QA has run. **BLOCKING.** |
| vehicleFetchCount cap at 21 is correct | ✅ Valid | Established in prior autoplan: cap at 21 not 20 |
| Stop-tap race fix is ~5-10 lines | ✅ Valid | 1-line guard in `loadDepartures(for:)` |

### 0B: Existing Code Leverage

| Sub-problem | Existing code |
|-------------|--------------|
| CHANGELOG update | Manual edit to CHANGELOG.md |
| Binary upload | Xcode Organizer → Distribute |
| TestFlight | Same upload flow, different destination |
| Stop-tap race | `loadDepartures(for:)` in TransportMapView.swift ~line 519 |
| vehicleFetchCount | `vehicleFetchCount += 1` at ~line 651 — 1-line guard |
| Dead code removal | Delete WelcomeOverlayView.swift (326 lines, no other references) |

### 0C: Dream State

```
CURRENT:
  v1.6 on main. 12-screen onboarding live. Screenshots on ASC.
  Binary not uploaded. SwiftData save unverified. VBB API: zero fallback.

THIS PLAN (corrected):
  v1.6 live in App Store after TestFlight beta + SwiftData QA.
  v1.7 ships: 2 bug fixes + WelcomeOverlayView deleted + TODOS tidy.

12-MONTH IDEAL:
  GTFS-RT fallback in place (parallel data source, not primary).
  Analytics review between every version.
  TestFlight standard for major UI changes.
  Portfolio differentiation clear (BTM = live positions, MyStop = departures-focused).
  Day-7 retention tracked.
```

### 0C-bis: Implementation Alternatives

```
APPROACH A: TestFlight first (RECOMMENDED — auto-decided P1)
  Effort: Near-zero marginal cost (same archive → different destination)
  Risk: Low
  Pros: Catches device-specific issues before App Store review
  Cons: 48-hour delay before submission

APPROACH B: Direct App Store submission (deferred from prior plan)
  Effort: Same as A
  Risk: Medium (12-screen onboarding untested on real devices)
  Cons: Rating damage if onboarding crashes
```

### 0D: SELECTIVE EXPANSION Analysis

Expansions auto-approved:
1. **Add SwiftData QA step to Plan A** — blocking (P1). In blast radius. Zero effort.
2. **Add TestFlight step to Plan A** — marginal cost (P1). Completeness requires it.
3. **Elevate VBB API risk from P3 → P2 in TODOS** — informational bump, not new work.

Expansions deferred:
- Portfolio consolidation (ocean, not lake — /office-hours)
- Analytics review cycle (TODOS.md — separate habit to build)
- Post-onboarding aha moment instrumentation (TODOS.md)
- Competitive moat features (widget, alerts, crowdsourced delays — /office-hours)

### 0E: Temporal Interrogation

```
HOUR 1: QA SwiftData save on device (T0 blocking gate)
HOUR 2: TestFlight build — archive → distribute → invite testers
HOUR 24-48: TestFlight observation window
HOUR 49: Add CHANGELOG v1.6 entry, submit to App Store
HOUR 50-65: ASC processing (~15-30 min) + review (usually 1-2 days)
AFTER APPROVAL: v1.7 branch — stop-tap race, vehicleFetchCount, delete WelcomeOverlayView
```

### 0F: Mode Confirmed — SELECTIVE EXPANSION

Two additions to Plan A (SwiftData QA + TestFlight). All other expansions deferred.

### NOT in Scope

- VBB fallback (elevated priority but separate sprint)
- OnboardingView A/B testing
- Portfolio consolidation
- Unit test harness

### What Already Exists

- `FavoritesService.saveStopFavorite` — the save path; needs device QA
- `loadDepartures(for:)` — stop-tap entry point; 1-line guard needed
- `vehicleFetchCount` @AppStorage at ~line 651 — 1-line cap needed
- `WelcomeOverlayView.swift` — dead, 326 lines, zero references post-PR #4

### Error & Rescue Registry

| Error | When | Rescue |
|-------|------|--------|
| SwiftData save fails silently | Device QA step | OSLog shows FavoritesService error; fix before submit |
| Archive fails | Wrong scheme/signing | Check scheme = BerlinTransportMap, target = Any iOS Device |
| TestFlight crashes onboarding | TestFlight observation | Fix crash, re-archive, re-upload before App Store submit |
| ASC upload rejected | Version collision | Ensure build 12 not already on ASC |
| VBB API goes dark | Any time | Users see empty map — no mitigation until GTFS-RT fallback |

### Failure Modes Registry

| Mode | Probability | Impact | Plan |
|------|-------------|--------|------|
| SwiftData save broken | Medium | High | Block on device QA (new Plan A Step 0) |
| Onboarding crash on real device | Low-Medium | High | TestFlight 48h window (new Plan A Step 0.5) |
| VBB API failure | Low (community-hosted) | Critical | P2 TODOS — prototype GTFS-RT fallback |
| Wrong departures on rapid stop tap | Medium | High | v1.7 fix (5-10 lines) |
| Review prompt spams past count 20 | High (reproducible) | Medium | v1.7 fix (1 line) |

### CEO Completion Summary

| Item | Status |
|------|--------|
| Premises verified | ✅ 5/7 valid, 1 unverified (SwiftData — now blocking QA), 1 N/A |
| Error & Rescue Registry | ✅ 5 error modes documented |
| Failure Modes Registry | ✅ 5 modes with probability/impact |
| Dream state documented | ✅ |
| NOT in scope documented | ✅ |
| Plan A corrections applied | ✅ 2 additions (SwiftData QA + TestFlight) |
| TODOS.md VBB escalation | Pending (write at end) |
| Taste decisions surfaced | ✅ 2 (portfolio, hasSeenWelcome rename) |

---

**PHASE 1 COMPLETE.** Codex: usage limit (subagent-only). Claude subagent: 9 findings (3 critical, 4 high, 2 medium). Auto-decided 7, surfaced 2 taste decisions at gate. Passing to Phase 2.

---

## Phase 2: Design Review [subagent-only — Codex usage limit Apr 16]

### Design Litmus Scorecard

| Dimension | Score | Key Issue |
|-----------|-------|-----------|
| Information hierarchy | 6/10 | Hardcoded font sizes break Dynamic Type on all 12 screens |
| Missing states | 4/10 | Location denial silent, SwiftData failure silent, tip no loading state |
| User journey | 5/10 | Tinder cards = 4 screens of friction with zero personalization payoff |
| Specificity | 7/10 | Actual strings and colors present; some broken promises (TransitTypeScreen) |
| Design system alignment | 5/10 | Hardcoded `system(size:)` fonts, emoji-only color indicators, delay badge missing `.monospacedDigit()` |
| Accessibility | 7/10 | `reduceMotion` respected; Dynamic Type broken by hardcoded sizes |
| Anti-haunting | 4/10 | Fake "live" departure data, silent save failures, no back button — three exit triggers |

**Overall design score: 5.4/10**

### Findings and Auto-Decisions

**[CRITICAL → AUTO-FIX] Location permission denial silent dead end**
`OnboardingView.swift:897-903` — `onNext()` called unconditionally 1.5s after auth request. If user taps "Don't Allow", onboarding advances without any acknowledgment that their experience will be degraded.
→ **Fix (v1.7):** Check `CLAuthorizationStatus` in `ProcessingScreen`. If `.denied`, show inline: "Location off — map starts at Alexanderplatz. Enable in Settings → Privacy anytime."

**[HIGH → TASTE DECISION] Tinder card mechanic earns nothing**
`OnboardingView.swift:573-688` — swipe direction (`nextCard()`) is the same action whether user liked or disliked. Output not stored anywhere. `SolutionScreen` already does personalization from `PainScreen`. Four screens of friction with no product payoff.
→ **TASTE: Wire swipe direction to personalization OR cut the screen entirely.** Surfaced at gate.

**[HIGH → AUTO-FIX] SwiftData save failure → false "stops are live"**
`OnboardingView.swift:288-305` — save errors logged but user advances anyway. `ValueDeliveryScreen` claims "These go straight to your Favorites ✓" without verifying the save succeeded.
→ **Fix (v1.7):** Re-query SwiftData on `ValueDeliveryScreen` appearance; show conditional "Stops saved ✓" vs. "Couldn't save your stops — re-add them in Favorites."

**[HIGH → AUTO-FIX] MiniDepartureBoard shows hardcoded data as "right now"**
`OnboardingView.swift:1122` headline: "Here's what's coming right now." + static `sampleDepartures`. Departure times never change — "2 min to Ruhleben" is always 2 min.
→ **Fix (v1.7):** Change headline to "Example departures — your live data loads in the app." Or fetch real data during ProcessingScreen (more work, better UX — TASTE for scope).

**[HIGH → AUTO-FIX] Tip purchase no loading/error state**
`OnboardingView.swift:1252-1278` — buttons not disabled during `purchaseTip` async call. No loading indicator. No error message on failure. Double-tap possible.
→ **Fix (v1.7):** Disable tip buttons while `store.state == .loading`. Show inline error if `store.state == .failed`.

**[MEDIUM → TASTE DECISION] TransitTypeScreen selections collected but never used**
`OnboardingView.swift:786-853` — `selectedTransitTypes` set collected but never persisted or passed downstream. Screen promises "We'll highlight these on your map."
→ **TASTE: Persist to `@AppStorage("preferredTransitTypes")` OR remove the screen.** Broken promises generate App Store reviews. Surfaced at gate.

**[MEDIUM → AUTO-FIX] No back button on 12-screen flow**
All screens — progress bar implies navigability; no back chevron anywhere. Users who misselect on step 2 are trapped.
→ **Fix (v1.7):** Add `<` back chevron for `step > 0 && step != 8` (ProcessingScreen can't go back).

**[LOW → AUTO-FIX] Hardcoded font sizes + emoji color-only indicator**
Multiple screens use `.font(.system(size: 34, weight: .bold))` — breaks Dynamic Type. Delay badge at line 1212 missing `.monospacedDigit()`. `TransitTypeScreen` emoji-only color indicators violate DESIGN.md.
→ **Fix (v1.7):** Replace with `.font(.largeTitle.bold())` / `.font(.title.bold())`. Add `.monospacedDigit()` to delay badge. Replace emoji transit type grid with VBB-colored line badges.

### Phase 2 — NOT in Scope

- Real live API call during ProcessingScreen (option b for fake departure data — too complex for v1.7)
- Full re-architecture of Tinder card screen (deferred pending taste decision)

### Phase 2 Completion Summary

| Item | Status |
|------|--------|
| All 7 design dimensions evaluated | ✅ |
| 8 findings identified | ✅ (3 critical/high auto-fixed, 2 taste decisions, 3 medium/low auto-fixed) |
| Design system alignment checked | ✅ vs DESIGN.md |
| Dual voices | Subagent ✅ / Codex: usage limit |
| New Plan B items added | ✅ 5 code fixes → v1.7 scope |

**PHASE 2 COMPLETE.** Claude subagent: 8 findings (1 critical, 3 high, 2 medium, 2 low). Auto-decided 6, surfaced 2 taste decisions. Overall design 5.4/10. Passing to Phase 3.

---

## Phase 3: Eng Review [subagent-only — Codex usage limit Apr 16]

### ENG DUAL VOICES — CONSENSUS TABLE

```
═══════════════════════════════════════════════════════════════
  Dimension                           Claude  Codex  Consensus
  ─────────────────────────────────── ─────── ─────── ─────────
  1. Architecture sound?               ✅      N/A    [subagent-only]
  2. Test coverage sufficient?         ⚠️      N/A    GAPS (no test harness)
  3. Performance risks addressed?      ✅      N/A    [subagent-only]
  4. Security threats covered?         ✅      N/A    [subagent-only]
  5. Error paths handled?              ❌      N/A    MISSING (tip purchase, location denial)
  6. Deployment risk manageable?       ⚠️      N/A    SwiftData QA + TestFlight required
═══════════════════════════════════════════════════════════════
SOURCE: subagent-only [codex usage limit until Apr 16]
```

### Section 1: Architecture — ASCII Dependency Diagram

```
ContentView
    ├── TransportMapView                    [MODIFIED v1.7: stop-tap guard, vehicleFetch cap]
    │     ├── VehicleRadarService           [unchanged — network layer]
    │     ├── openDepartures(for:)          [RACE FIX: guard selectedStop?.id == stop.id]
    │     └── loadVehicles()               [vehicleFetchCount: cap at 21]
    │
    └── OnboardingView (gated: !hasSeenWelcome)  [EXISTING v1.6]
          ├── @Environment(\.modelContext)  [requires ModelContainer in app entry point]
          ├── FavoritesService              [SwiftData write — UNVERIFIED on device]
          ├── CLLocationManager            [non-Sendable Swift 6 risk — wrap needed]
          ├── TipJarStore                  [BLOCKING: no .disabled during async purchase]
          └── WelcomeOverlayView.swift     [DEAD CODE — delete in v1.7]

Dead code confirmed: WelcomeOverlayView.swift — zero Swift imports/references post-PR #4.
```

### Section 2: Code Quality

- `saveSelectedStops()` has no idempotency guard — can be called multiple times. Add `var stopsSaved = false` guard. (Low risk currently since `advance()` only calls it at step==11 once.)
- `CLLocationManager` passed as non-Sendable into child struct. Safe today (project not at Swift 6 strict), but will error at full compliance. Wrap in `@Observable @MainActor final class LocationPermissionManager`.
- `ProcessingScreen` `.task` uses `try?` to suppress cancellation — masks real cancellation state. Replace with `guard !Task.isCancelled else { return }`.
- `ContentView` `#Preview` block lacks `.modelContainer(for: [TransportStopFavorite.self], inMemory: true)` — preview crashes without it.

### Section 3: Test Coverage Diagram

```
CODE PATH COVERAGE
═══════════════════════════════════════════════════════════════
[v1.7 changes]

openDepartures(for:) — stop-tap race
    ├── [GAP] Happy path: tap stop, departures load → NO TEST (manual T5)
    ├── [GAP] Race: tap A then B, verify B's data shown → NO TEST (manual T5)
    └── [GAP] Guard fires: stale A response discarded → NO TEST

vehicleFetchCount
    ├── [GAP] Prompt fires at count 5 → NO TEST (manual T6)
    ├── [GAP] Prompt fires at count 20 → NO TEST (manual T6)
    └── [GAP] Count capped at 21, no further prompts → NO TEST

OnboardingView — saveSelectedStops
    ├── [GAP] Saves 2 stops → SwiftData persists → NO TEST (manual T1)
    └── [GAP] Empty stop list → save no-ops → NO TEST

TipNudgeScreen — purchaseTip
    ├── [GAP] Buttons disabled during async → NO TEST (manual T2/T10)
    └── [GAP] Failure shows inline error → NO TEST (manual T3)

AUTOMATED COVERAGE: 0/12 paths tested
REASON: No test framework configured (no test/ dir, no XCTest targets)
MANUAL TEST PLAN: /Users/rd/.gstack/projects/dautovri-berlin-realtime-map/rd-main-ship-test-plan-20260413-001310.md

NOTE: Test framework bootstrap deferred — adding unit test harness is a separate P3 sprint.
All critical paths covered by 11 manual test cases in test plan artifact.
═══════════════════════════════════════════════════════════════
```

### Section 4: Performance

- `vehicleFetchCount` @AppStorage write on every vehicle fetch cycle (~30s) — acceptable. Single `UserDefaults` key write, no performance concern.
- `OnboardingView` loads 12 screens sequentially via `switch step {}` — all screens present in the view graph simultaneously as `@ViewBuilder` branches. No meaningful memory concern for 12 simple SwiftUI views.

### Section 5: Security

- No new network surface. No new auth paths. `FavoritesService` SwiftData writes are local-only. StoreKit 2 transactions handled by Apple's framework. Clean.

### Section 6: Deployment Risk

- **BLOCKING: Tip purchase double-tap** — must fix before App Store submission (payment path).
- **BLOCKING: SwiftData save unverified** — manual T1 required before submit.
- **RECOMMENDED: 48h TestFlight** — major onboarding rewrite, device testing required.
- WelcomeOverlayView deletion: zero risk (confirmed no references).

### Section 7: Dependencies

- VBB API: community-hosted, zero SLA. Elevated to P2 in TODOS.md. No v1.7 action.
- SwiftData: requires ModelContainer injection at app entry point. Already in place.
- StoreKit 2: requires real device/sandbox for payment path testing.

### Section 8: Tests

No automated tests exist. All critical paths covered by 11 manual test cases in test plan artifact. Automated test harness is P3 — separate sprint.

### Section 9: Migration

No SwiftData schema changes. No breaking @AppStorage key changes. `hasSeenWelcome` key remains unchanged (taste decision: rename vs. keep — surfaced at gate).

### Section 10: Privacy

`PrivacyInfo.xcprivacy` already covers location. No new data collection. SwiftData favorites are local-only. StoreKit transactions are Apple-managed.

### NOT in Scope (Eng)

- Unit test harness (P3 — separate sprint)
- GTFS-RT fallback (P2 TODOS — next sprint)
- Route replay (needs Favorite model changes)

### What Already Exists

- `openDepartures(for:)` and `loadDepartures(for:)` — 1-line guard needed
- `vehicleFetchCount += 1` at line 651 — 1-line `if vehicleFetchCount < 21 { }` wrap
- `TipNudgeScreen` buttons — add `.disabled(store.state == .loading)`
- `WelcomeOverlayView.swift` — delete the file
- TODOS.md WelcomeOverlay section — delete all items (not "mark")

### Eng Completion Summary

| Item | Status |
|------|--------|
| Architecture diagram | ✅ |
| Test diagram with path coverage | ✅ |
| Test plan artifact on disk | ✅ |
| Scope challenge with code analysis | ✅ |
| Failure modes registry | ✅ (in Phase 1) |
| BLOCKING finding added to Plan A | ✅ (tip purchase disabled state) |
| TODOS.md updates collected | ✅ |
| Dual voices | Subagent ✅ / Codex: usage limit |

**PHASE 3 COMPLETE.** Claude subagent: 8 findings (3 high, 3 medium, 2 low). 1 BLOCKING for v1.6 (tip purchase disabled state). 6 new v1.7 items. Zero cross-phase DX scope detected → Phase 3.5 skipped. Passing to Phase 4 (Final Gate).

---

---

## Decision Audit Trail

<!-- AUTONOMOUS DECISION LOG -->

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|----------------|-----------|-----------|---------|
| 1 | CEO | SwiftData device QA as blocking pre-submission gate | Mechanical | P1 completeness | Unverified payment/save path must not ship | Skip QA |
| 2 | CEO | TestFlight 48h before App Store | Mechanical | P1 completeness | Major onboarding rewrite; marginal cost zero | Direct submit |
| 3 | CEO | Elevate VBB API from P3 → P2 in TODOS | Mechanical | P2 boil lakes | Existential dependency, lower priority defers risk accumulation | Leave at P3 |
| 4 | CEO | Portfolio consolidation → /office-hours | Mechanical | P3 pragmatic | Ocean-sized, not this sprint | Block v1.6 |
| 5 | CEO | hasSeenWelcome rename | TASTE | P5 explicit | Keep vs. rename affects retained user re-engagement | — |
| 6 | CEO | Analytics review → TODOS.md | Mechanical | P6 bias to action | Good habit, not blocking | Gate v1.7 on data |
| 7 | Design | Location denial dead-end → inline message on ProcessingScreen | Mechanical | P1 completeness | Silent failure for a promised feature is a deceptive pattern | Leave silent |
| 8 | Design | Tinder card mechanic (wire vs. cut) | TASTE | P1 vs P5 | 4 screens of friction with zero payoff; cutting is simpler, wiring is more honest | — |
| 9 | Design | SwiftData false "live" → conditional confirmation message | Mechanical | P1 completeness | "Stops saved ✓" must be verified, not assumed | Trust the save |
| 10 | Design | Fake "right now" departure headline → "Example departures" | Mechanical | P1 completeness | Deceptive pattern erodes trust on first launch | Keep as-is |
| 11 | Design | Tip purchase loading/error state | Mechanical | P1 completeness | Payment path must have clear state feedback | Ship without |
| 12 | Design | TransitTypeScreen selections → persist OR remove | TASTE | P1 vs P3 | Broken promise must be resolved; keep-and-wire vs. remove | Leave broken |
| 13 | Design | Back button on steps 1-7, 9-12 | Mechanical | P1 completeness | 12-step flow with no back is a major exit trigger | No back button |
| 14 | Design | Hardcoded font sizes → Dynamic Type | Mechanical | P1 completeness | DESIGN.md requirement; accessibility regression | Leave hardcoded |
| 15 | Eng | Stop-tap race fix: confirmed correct | Mechanical | P1 completeness | Guard is sufficient; isLoadingDepartures reset on early return is correct | No change |
| 16 | Eng | Tip purchase disabled state → BLOCK v1.6 | Mechanical | P1 completeness | Payment path defect must not ship | Defer to v1.7 |
| 17 | Eng | CLLocationManager → @MainActor wrapper (v1.7) | Mechanical | P1 completeness | Swift 6 Sendable risk; low impact today, breaking at compliance | Ignore |
| 18 | Eng | saveSelectedStops idempotency guard | Mechanical | P5 explicit | Defensive; currently safe but correctness requires it | Skip |
| 19 | Eng | #Preview ModelContainer inject | Mechanical | P5 explicit | Crash prevention; low effort | Skip |
| 20 | Eng | WelcomeOverlayView TODOS: delete not mark | Mechanical | P5 explicit | Dead items cause confusion; deletion is cleaner | Mark as obsolete |
| 21 | QA (post-review) | TinderCards: cut (TASTE → resolved) | Resolved | P5 explicit | Cut in commit 0030fc1. Flow collapses to 9 screens. | Wire swipe direction |
| 22 | QA (post-review) | TransitTypeScreen: removed (TASTE → resolved) | Resolved | P5 explicit | Removed in commit 0030fc1. Broken promise eliminated. | Persist to AppStorage |
| 23 | QA (post-review) | hasSeenWelcome → hasSeenOnboardingV2 (TASTE → resolved) | Resolved | P1 completeness | Renamed in commit 0030fc1. Retained users will see new flow. | Keep old key |
| 24 | QA (post-review) | Tip purchase disabled state — BLOCKING fixed | Resolved | P1 completeness | .disabled(store.state == .loading) added, commit 0030fc1. | Defer to v1.7 |
| 25 | QA (post-review) | ProcessingScreen stuck — CRITICAL fixed | Resolved | P1 completeness | .task(id: step) fix, commit 53dd2b3. Root: SwiftUI task id semantics. | — |
| 26 | QA (post-review) | Fake "right now" headline — fixed | Resolved | P1 completeness | "Example departures" copy, commit 547c014. | — |

---

## Cross-Phase Themes

**Theme: Silent failure paths** — flagged in Phase 1 (SwiftData unverified), Phase 2 (location denial dead-end, SwiftData false confirmation), Phase 3 (error paths missing). High-confidence signal. Pattern: every user-facing async operation in this codebase fails silently. Systematic fix needed in v1.7 before v1.8 adds more surface.

**Theme: No test coverage** — flagged in Phase 1 (P3 item), Phase 3 (0/12 paths automated). High-confidence signal. Not blocking v1.6 (manual test plan covers critical paths) but becomes load-bearing as the app grows. Test harness before v1.8.

**Theme: VBB API single point of failure** — flagged in Phase 1 (elevated P2) and Phase 3 Section 7. Community-hosted, no SLA. Zero mitigation in scope. Next sprint: prototype GTFS-RT fallback.

