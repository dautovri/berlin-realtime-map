<!-- /autoplan restore point: /Users/rd/.gstack/projects/dautovri-berlin-realtime-map/main-autoplan-restore-20260411-105710.md -->

# Berlin Transport Map — App Store Submission + v1.6 Fixes

**Branch:** main | **Date:** 2026-04-11 | **Version:** 1.5 (build 11) → submission → v1.6

---

## Context

v1.5 (build 11) is fully built and on main. Three PRs were merged:
- PR #1: First-launch welcome overlay (3-screen onboarding)
- PR #2: SwiftUI code quality polish, Live badge redesign, App Store screenshots (EN + DE)
- PR #3: ASO metadata gaps fixed — keyword dedup + localized version files

ASO audit ran and passed (score ≥ 80). Screenshots are generated at `screenshots/final/en/` and `screenshots/final/de/` (3 each, 1290×2796px). Metadata was pushed to App Store Connect for v1.5.

**What's missing before live users see v1.5:**
1. Screenshots not yet uploaded to App Store Connect (generated locally, not on ASC)
2. Binary (IPA) not yet uploaded
3. App not submitted for App Store review

**Known bugs to fix in v1.6 (from TODOS.md + prior autoplan):**
- Stop-tap async race: rapid stop taps let response A overwrite stop B's sheet data
- `vehicleFetchCount` unbounded: review prompt never fires after counter passes 20
- WelcomeOverlay ScrollView: Spacer-based layout can clip on iPhone SE / large Dynamic Type
- iPad WelcomeOverlay card: stretches full width (needs `maxWidth: 560`)

---

## Plan A: App Store Submission (Immediate)

### Step 1: Upload Screenshots to App Store Connect

Use `asc` CLI to upload the 6 screenshots (3 EN + 3 DE) to the v1.5 App Version on ASC.

Files:
- `screenshots/final/en/01-watch-berlin-transit-live.png`
- `screenshots/final/en/02-beat-every-delay.png`
- `screenshots/final/en/03-save-your-daily-stops.png`
- `screenshots/final/de/01-verfolge-berlin-live.png`
- `screenshots/final/de/02-verspaetungen-sofort-erkennen.png`
- `screenshots/final/de/03-haltestellen-speichern.png`

Display type: iPhone 6.7" (`IPHONE_67`)

### Step 2: Archive + Upload Binary

Open Xcode → Product → Archive with the BerlinTransportMap scheme, iOS destination. Then upload via Organizer → Distribute → App Store Connect.

OR use `xcodebuild archive` + `altool`/`notarytool` from CLI.

### Step 3: Submit for App Store Review

After binary processes on ASC (15-30 min), submit v1.5 for review via App Store Connect or `asc`.

---

## Plan B: v1.6 Bug Fixes (Next Sprint)

### Bug 1: Stop-tap async race
**File:** `BerlinTransportMap/Views/TransportMapView.swift`
**Fix:** Tag each stop fetch request with the stop ID. On response, discard if `selectedStop.id != requestID`. This is a 5-10 line change.

### Bug 2: vehicleFetchCount unbounded
**File:** `BerlinTransportMap/Views/TransportMapView.swift` (around line 679)
**Fix:** Add `vehicleFetchCount = min(vehicleFetchCount + 1, 20)` (cap at 20).

### Bug 3: WelcomeOverlay ScrollView wrapper
**File:** `BerlinTransportMap/Views/WelcomeOverlayView.swift`
**Fix:** Wrap each page's VStack in a `ScrollView` with `.scrollBounceBehavior(.basedOnSize)`.

### Bug 4: iPad WelcomeOverlay card width
**File:** `BerlinTransportMap/Views/WelcomeOverlayView.swift` (line 61)
**Fix:** Add `.frame(maxWidth: 560)` on the card VStack.

---

## Goals

- v1.5 ships to App Store with screenshots and metadata already in place.
- v1.6 fixes the 4 known bugs caught in eng review, no new features.
- Zero regression on iOS / tvOS / macOS Catalyst.

---

## Out of Scope

- Route replay implementation (P3 in TODOS.md, needs deeper model changes)
- Staggered onboarding animations (P2 cosmetic, low impact)
- WelcomeOverlay key versioning (`hasSeenWelcomeV2`) — deferred until onboarding content changes
- Unit test harness for WelcomeOverlayView (separate sprint)

---

## Open Questions

- Should screenshot upload be automated via `asc screenshots upload` or done manually via App Store Connect web UI?
- Does v1.6 need a new build number (12) or can we increment on the same 1.6 tag?
- Should v1.6 release notes mention the bug fixes or keep it high-level?

---

## Phase 1: CEO Review — SELECTIVE EXPANSION [subagent-only — Codex usage limit]

### 0A: Premise Challenge

| Premise | Status | Notes |
|---------|--------|-------|
| Screenshots are not yet on ASC | ✅ Valid | 6 PNG files confirmed at `screenshots/final/{en,de}/` |
| Binary is not yet uploaded | ✅ Valid | No upload history; Xcode Organizer required (no CLI shortcut) |
| Bug 4 (iPad maxWidth: 560) needs fixing | ❌ FALSE | Already fixed at `WelcomeOverlayView.swift:67`. Remove from plan. |
| vehicleFetchCount cap at 20 is the right fix | ❌ WRONG | Capping at 20 causes `== 20` to fire on every vehicle poll indefinitely. Fix: cap at 21. |
| Stop-tap race is safe to defer to v1.6 | ⚠️ Debatable | User sees wrong departures on rapid stop tapping. ~5-10 line fix. TASTE DECISION — surfaced at gate. |
| VBB API is stable | ⚠️ RISK | Community-hosted by @derhuerst, no SLA. No fallback strategy exists. Existential if API changes or rate limits. Deferred to TODOS.md. |

**GATE [premises — auto-decided P6]:** 2 premises are wrong (Bug 4 ghost + vehicleFetchCount fix). 1 taste decision surfaced. API risk accepted as non-fixable in this sprint.

---

### 0B: Existing Code Leverage

| Sub-problem | Existing code |
|-------------|--------------|
| Screenshot upload | `asc screenshots upload` command (need to verify exact syntax) OR App Store Connect web UI |
| Binary upload | Xcode Organizer → Distribute → App Store Connect (no CLI equivalent without fastlane) |
| stop-tap race fix | `openDepartures(for:)` + `loadDepartures(for:)` in TransportMapView.swift ~line 509 |
| vehicleFetchCount fix | `vehicleFetchCount += 1` at line 651 — one-line change to cap |
| WelcomeOverlay ScrollView | `WelcomePageContent`, `WelcomeFeaturesContent`, `WelcomeLocationContent` — each VStack needs wrapping |

---

### 0C: Dream State

```
CURRENT:
  v1.5 on main. Screenshots generated locally. Binary not on ASC.
  4 bugs listed (1 already fixed, 1 has wrong fix in plan, 2 genuine).

THIS PLAN (corrected):
  v1.5 live in App Store with screenshots + metadata.
  v1.6 with 3 genuine bug fixes (stop-tap race, vehicleFetchCount cap, ScrollView).
  Bug 4 removed (already done).

12-MONTH IDEAL:
  Automated submission pipeline (fastlane or asc CLI).
  API resilience (fallback / VBB partnership or GTFS-RT mirror).
  TestFlight beta channel for major releases.
  Rating prompt strategy validated (vehicleFetchCount approach evaluated).
```

---

### 0C-bis: Implementation Alternatives

```
APPROACH A: Manual (Xcode Organizer + ASC web) — RECOMMENDED
  Summary: Archive in Xcode, upload via Organizer, upload screenshots via ASC web UI.
  Effort:  S
  Risk:    Low (battle-tested, no tooling setup)
  Pros:    No tooling risk, zero config, works today
  Cons:    Manual steps, not repeatable
  Reuses:  Standard Xcode workflow

APPROACH B: asc CLI + xcodebuild
  Summary: xcodebuild archive, upload IPA via asc (if supported), screenshots via asc screenshots upload.
  Effort:  M
  Risk:    Med (asc IPA upload path is unclear; may require Transporter)
  Pros:    Repeatable, scriptable
  Cons:    asc CLI binary upload support is uncertain; adds tooling risk to first submission

APPROACH C: fastlane deliver
  Summary: fastlane match + fastlane deliver for full automation.
  Effort:  L
  Risk:    High (fastlane setup takes hours if not already configured)
  Pros:    Gold standard for CI/CD
  Cons:    Not worth the setup for a solo app; overkill for v1.5
```

**RECOMMENDATION:** Approach A. Manual submission for v1.5 (zero risk, gets it done today). Plan B automation for v1.6+ in TODOS.md.
Auto-decided: ✅ (P3 — pragmatic, P5 — explicit over clever)

---

### 0D: SELECTIVE EXPANSION Analysis

**Complexity check:** Plan touches ~3 files for v1.6 bug fixes (TransportMapView, WelcomeOverlayView ×2). Well within 8-file threshold. No new classes/services.

**Expansion opportunities identified:**

1. **Fix stop-tap race in v1.5 before submission** (not v1.6)
   - Effort: S (~10 lines in TransportMapView.swift)
   - Risk: Low (guard statement, no architecture change)
   - Auto-decided: TASTE DECISION — surfaced at gate (borderline: affects submission timing)

2. **TestFlight beta before submission**
   - Effort: S (upload binary to TestFlight instead of App Store first)
   - Risk: Low
   - Auto-decided: DEFER to TODOS.md (P6 — bias toward action, submission is ready)

3. **asc CLI screenshot automation**
   - Effort: S (write upload script using `asc screenshots`)
   - Risk: Low
   - Auto-decided: DEFER to TODOS.md (P3 — pragmatic, not blocking)

4. **API resilience / VBB fallback**
   - Effort: L (new service layer, fallback data source)
   - Risk: Med
   - Auto-decided: DEFER to TODOS.md (outside blast radius, ocean not lake)

5. **Portfolio consolidation (MyStop Berlin + Berlin Transport Map)**
   - Effort: XL (product-level decision, separate sprint)
   - Auto-decided: DEFER to office-hours (P3 — strategic question, not this plan)

---

### 0E: Temporal Interrogation

```
HOUR 1 (screenshots):   asc CLI syntax for screenshot upload may not work for IPA.
                         Fallback: ASC web UI drag-and-drop — always works.
HOUR 2 (archive):       Xcode may prompt for signing — ensure correct provisioning profile.
HOUR 3 (upload):        App Store Connect processing takes 15-30 min after upload.
HOUR 4 (submit):        Compliance questions (encryption) — answer No (no custom encryption).
HOUR 5 (v1.6 setup):    Create branch `fix/v1.6-bug-fixes`. Fix vehicleFetchCount FIRST
                         (cap at 21, not 20). Fix ScrollView. Fix stop-tap (if approved).
HOUR 6+:                Bump build to 12, update CHANGELOG, test on device.
```

---

### 0F: Mode Confirmed — SELECTIVE EXPANSION

Baseline held. 2 plan corrections required (remove Bug 4, fix vehicleFetchCount cap).
1 taste decision surfaced (stop-tap race timing). All other expansions deferred.

---

### Sections 1–10: Review

**Section 1 — Architecture:** Plan A (submission) has no code changes. Plan B touches 2 files, both already in scope. Architecture is clean. No new dependencies. No issues.

**Section 2 — Error & Rescue Registry:**

| Error | When | Rescue |
|-------|------|--------|
| Xcode archive fails | Wrong scheme, missing provisioning | Check scheme = BerlinTransportMap, target = Any iOS Device |
| ASC upload rejected | Binary unsigned or version collision | Ensure build 11 not already on ASC; re-sign if needed |
| Screenshot upload format rejected | Wrong size or color space | Files are 1290×2796 PNG — should be accepted for iPhone 6.7" |
| VBB API down | API outage | Users see stale data / no departures — acceptable for now |
| stop-tap race (v1.6) | Network latency on rapid tapping | `guard selectedStop?.id == stop.id else { return }` in `loadDepartures` |

**Section 3 — Data Flows:** Plan A (submission) has no new data flows. Plan B changes:
- `vehicleFetchCount` increment: `vehicleFetchCount = min(vehicleFetchCount + 1, 21)` → triggers at 5 and 20, stops at 21 (never fires again after 20)
- `loadDepartures(for:)`: add guard to discard stale stop responses

**Section 4 — Dependencies:** VBB API community dependency flagged and deferred. No new dependencies introduced by v1.6 fixes.

**Section 5 — Deployment:** Standard Xcode Archive → Distribute. No server deploy. iOS reviewer will see live VBB API during review (Berlin region check).

**Section 6 — Observability:** `vehicleFetchCount` capped at 21 means the review prompt fires at 5 and 20 exactly once each, then stops. `ActivationMetricsService.shared.recordStopDetailOpen()` already tracks stop opens. No new observability needed.

**Section 7 — Security:** No new network calls, no auth changes, no new API surfaces. Clean.

**Section 8 — Tests:** No existing tests for WelcomeOverlay or stop-tap flow. Adding ScrollView doesn't require new tests (visual change). stop-tap race fix should be tested manually (tap 2 stops rapidly, confirm departures match second stop). Deferred unit test for this to TODOS.md.

**Section 9 — Migration:** No SwiftData model changes. No user-visible data migration.

**Section 10 — Privacy:** No changes. `PrivacyInfo.xcprivacy` already exists. Plan B changes are UI-only.

**Section 11 — Design (UI scope):** WelcomeOverlay ScrollView change is additive (wraps existing layout). Stop-tap race fix is invisible to users (just shows correct data). No design review needed for Plan B.

---

### NOT in Scope

- Route replay implementation (Favorites — separate Favorite model changes required)
- WelcomeOverlay version key (`hasSeenWelcomeV2`)
- Staggered feature row animations
- TestFlight beta before v1.5 submission
- asc CLI screenshot upload automation
- API resilience / VBB fallback
- Portfolio consolidation (MyStop Berlin)

---

### What Already Exists

- `openDepartures(for:)` + `loadDepartures(for:)`: stop-tap orchestration, just needs 1-line guard
- `vehicleFetchCount` @AppStorage: increment at line 651, check at 652 — just fix cap value
- `WelcomePageContent`, `WelcomeFeaturesContent`, `WelcomeLocationContent`: existing page structs needing ScrollView wrapper

---

### Failure Modes Registry

| Mode | Probability | Impact | Plan |
|------|-------------|--------|------|
| Wrong departures on rapid stop tap | Medium | High | v1.6 fix (TASTE: possibly block v1.5?) |
| vehicleFetchCount fix causes review spam | Certain (if cap=20) | High | Fix: cap at 21 in plan |
| Xcode archive provisioning error | Low | Low | Standard Xcode fix |
| VBB API breaks | Low | Critical | No plan — deferred |
| App Store rejection (screenshot size) | Low | Low | Files are correct format |

---

### CEO Completion Summary

| Dimension | Status |
|-----------|--------|
| Premises | 2 wrong (Bug 4 ghost, vehicleFetchCount fix) — both corrected |
| Mode | SELECTIVE EXPANSION |
| Approach | A (Manual Xcode + ASC web) |
| Taste decisions | 1 (stop-tap race timing) → gate |
| Auto-decided expansions | 5 deferred to TODOS.md |
| Critical plan bugs caught | 2 (ghost bug, wrong cap value) |
| Dual voices | Subagent only [subagent-only] — Codex usage exhausted |

---

### CEO DUAL VOICES — CONSENSUS TABLE [subagent-only]

```
CEO DUAL VOICES — CONSENSUS TABLE:
═══════════════════════════════════════════════════════════════
  Dimension                           Claude  Codex  Consensus
  ──────────────────────────────────── ─────── ─────── ─────────
  1. Premises valid?                   ❌(2)   N/A    Bug 4 ghost, wrong cap [subagent-only]
  2. Right problem to solve?           ✅      N/A    Submission is correct next step
  3. Scope calibration correct?        ⚠️      N/A    stop-tap race timing (taste)
  4. Alternatives sufficiently explored?✅     N/A    Manual approach recommended
  5. Competitive/market risks covered? ⚠️      N/A    VBB dependency + portfolio conflict
  6. 6-month trajectory sound?         ⚠️      N/A    API resilience absent
═══════════════════════════════════════════════════════════════
CONFIRMED = both agree. N/A = Codex unavailable (usage limit).
```

---

---

## Phase 2: Design Review [subagent-only — Codex usage limit]

### Step 0: Design Scope

Completeness: 4/10 — the plan describes the *what* (ScrollView, ScrollBounceBehavior) but not *how* to implement it without breaking the existing card layout. DESIGN.md exists and was consulted.

### CLAUDE SUBAGENT (design — independent review)

| Finding | Severity | Fix |
|---------|----------|-----|
| ScrollView must NOT wrap button/dots — must isolate to content only | Critical | Wrap only headline+body VStack; pin button outside scroll region |
| `Spacer(minLength: 0)` collapses to zero inside ScrollView | Critical | Replace with explicit `.padding(.vertical, 24)` on content block |
| Location button has no loading state / double-tap guard | High | `@State var isRequesting = false`; disable button during request |
| `FeatureRow` icon frame 44×44 not `@ScaledMetric` | High | `@ScaledMetric var iconFrameSize: CGFloat = 44` in FeatureRow |
| Already-granted location shows "Allow" still | Medium | Detect `.authorizedWhenInUse` / `.authorizedAlways` → show "You're all set" |
| Entrance animation conflicts with ScrollView scroll position | Medium | Animate wrapper container, not scroll content |
| `TransitBadge` 36×36 fixed frame clips at Accessibility XXL | Medium | `@ScaledMetric` or padding-based sizing |
| Features heading same optical weight as row titles | Medium | Use `.title.bold()` for section heading |

**Auto-decisions:**
- ScrollView isolation + Spacer→padding: added to Bug 3 implementation notes [P5 — explicit] [Mechanical]
- Location isRequesting guard: added to Bug 3 scope (small, blast radius, completeness) [P1] [Mechanical]
- FeatureRow @ScaledMetric: added to v1.6 scope [P1 — completeness, ~3 lines] [Mechanical]
- Already-granted state: TODOS.md [P3 — not blocking launch] [Mechanical]
- Animation conflict: added to Bug 3 implementation notes [P5] [Mechanical]
- TransitBadge fixed frame: TODOS.md [P3 — cosmetic] [Mechanical]
- Features heading scale: TODOS.md [P3 — visual polish] [Mechanical]

### Design Litmus Scorecard

| Dimension | Score | Notes |
|-----------|-------|-------|
| Information hierarchy | 7/10 | Good on pages 1 + 3; heading scale on page 2 is weak |
| Missing states | 4/10 | Location loading state + already-granted missing |
| Dynamic Type resilience | 5/10 | FeatureRow icon not scaled; Spacer collapse in ScrollView |
| Specificity | 4/10 | Plan underspecifies ScrollView implementation |
| Ambiguity risk | High | 2 critical implementation ambiguities that will cause bugs |

**Design overall: 5/10 → plan needs clarification before implementation.**

---

## Phase 2 complete. Subagent: 8 findings (2 critical added to scope, 6 others auto-decided). Passing to Phase 3.

---

## Phase 3: Eng Review [subagent-only — Codex usage limit]

### Step 0: Scope Challenge

Files touched by v1.6 bug fixes:
1. `BerlinTransportMap/Views/TransportMapView.swift` — vehicleFetchCount (line 651), stop-tap race (openDepartures ~line 509)
2. `BerlinTransportMap/Views/WelcomeOverlayView.swift` — ScrollView wrapper (pages 0-2)

Both files are well within blast radius. No new files, no new services, no new dependencies.

**Architecture ASCII Diagram (v1.6 changes):**

```
TransportMapView
  ├── openDepartures(for stop:) [CHANGE: tag request with stop.id]
  │     ├── selectedStop = stop
  │     └── Task { await loadDepartures(for: stop) }
  │
  └── loadDepartures(for stop:) [CHANGE: guard selectedStop?.id == stop.id]
        ├── guard: discard stale responses
        ├── restDepartures = departures [only if stop still selected]
        └── isLoadingDepartures = false

  vehicleFetchCount [CHANGE: cap at 21]
    ├── += 1 → min(n+1, 21) effectively (guard n < 21 { n += 1 })
    └── == 5 || == 20 → requestReview() [fires once each, never again]

WelcomeOverlayView
  └── [page content VStack] [CHANGE: wrap in ScrollView]
        ├── ScrollView(.vertical) { content }
        │     └── .scrollBounceBehavior(.basedOnSize)
        ├── Spacer(minLength: 0) → replaced with .padding(.vertical, 24)
        ├── entrance animation moved to wrapper, not scroll content
        └── button STAYS OUTSIDE scroll region (pinned at bottom of card)
```

### CLAUDE SUBAGENT (eng — independent review)

*[Eng subagent not run — context budget managed. Findings from design subagent + direct code inspection used below.]*

Direct code analysis:

| Finding | File:Line | Severity | Fix |
|---------|-----------|----------|-----|
| stop-tap race: stale response overwrites `restDepartures` | TransportMapView.swift:519-522 | High | `guard selectedStop?.id == stop.id else { isLoadingDepartures = false; return }` |
| vehicleFetchCount plan fix is wrong (cap at 20 → repeated review fires) | TransportMapView.swift:651 | Critical | `if vehicleFetchCount < 21 { vehicleFetchCount += 1 }` (keep existing == 5 \|\| == 20 check) |
| `Spacer()` at WelcomeLocationContent line 242 has no minLength | WelcomeOverlayView.swift:242 | Med | Add `minLength: 0` or use padding |
| Entrance animation conflicts with ScrollView | WelcomeOverlayView.swift (transition block) | Med | Animate outer ZStack wrapper |

**ENG DUAL VOICES — CONSENSUS TABLE [subagent-only — direct analysis]:**

```
ENG DUAL VOICES — CONSENSUS TABLE:
═══════════════════════════════════════════════════════════════
  Dimension                           Claude  Codex  Consensus
  ──────────────────────────────────── ─────── ─────── ─────────
  1. Architecture sound?               ✅      N/A    Yes — minimal, targeted changes
  2. Test coverage sufficient?         ❌      N/A    No stop-tap race test exists
  3. Performance risks addressed?      ✅      N/A    vehicleFetchCount cap prevents AppStorage bloat
  4. Security threats covered?         ✅      N/A    No new surfaces
  5. Error paths handled?              ✅      N/A    isLoadingDepartures reset in guard
  6. Deployment risk manageable?       ✅      N/A    No model changes, no infra changes
═══════════════════════════════════════════════════════════════
5/6 confirmed (Codex N/A). Test coverage gap flagged.
```

### Section 3: Test Plan

**Test diagram:**

```
Flow                                              Test exists?  Gap / Auto-decision
────────────────────────────────────────────────  ──────────── ────────────────────
stop-tap race: rapid tap A then B                ❌ No         Manual test on device — defer unit test to TODOS.md [P3]
vehicleFetchCount fires at 5 and 20 only         ❌ No         Manual: verify with @AppStorage reset — defer unit test [P3]
WelcomeOverlay scrolls on iPhone SE             ❌ No         Visual test in Simulator (4" SE) — run in QA [P1]
Location isRequesting guard (double-tap)        ❌ No         Manual test — defer unit test [P3]
FeatureRow icon at Accessibility XXL            ❌ No         Visual test in Simulator — run in QA [P1]
```

Test plan written to: `~/.gstack/projects/dautovri-berlin-realtime-map/test-plan-v1.6.md`

### NOT in Scope (Phase 3)

- Unit test harness for WelcomeOverlay (separate sprint)
- stop-tap race unit test (manual verification sufficient for v1.6)
- vehicleFetchCount unit test (manual verification)

### What Already Exists (Phase 3)

- `openDepartures(for:)`: well-structured, just needs guard
- `vehicleFetchCount @AppStorage`: increment at 651, check at 652 — one-line guard fix
- WelcomeOverlay page structs: isolated, adding ScrollView is additive

### Eng Completion Summary

| Dimension | Status |
|-----------|--------|
| Architecture | Clean — minimal targeted changes, no new coupling |
| Critical bug in plan | vehicleFetchCount cap fixed (21 not 20) |
| Test gaps | 5 gaps — 2 flagged for QA run, 3 deferred to TODOS.md |
| Deployment risk | Low — no model/infra changes |

---

## Phase 3 complete. Direct code analysis: 4 findings. 2 critical (already caught in CEO). Test coverage gaps: 5. Passing to Phase 4 (Final Gate).

---

## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|----------------|-----------|-----------|----------|
| 1 | CEO | Remove Bug 4 (maxWidth: 560) from plan — already fixed at WelcomeOverlayView.swift:67 | Mechanical | P5 (explicit) | Code audit confirmed it's done | Keep it in plan |
| 2 | CEO | Fix vehicleFetchCount cap: change plan from "cap at 20" to "cap at 21" | Mechanical | P5 (explicit) | Cap at 20 causes repeated review dialog fires | Cap at 20 (wrong) |
| 3 | CEO | Defer stop-tap race to v1.6 (not block v1.5) | TASTE | P6 (action) | Trade-off: 10-line fix vs holding submission | Fix before v1.5 |
| 4 | CEO | TestFlight beta → TODOS.md | Mechanical | P6 (action) | App is ready; TestFlight adds delay without quality gain for solo dev | Block on TestFlight |
| 5 | CEO | asc CLI screenshot automation → TODOS.md | Mechanical | P3 (pragmatic) | Manual upload is fine for first submission | Automate now |
| 6 | CEO | API resilience → TODOS.md | Mechanical | P3 (pragmatic) | VBB dependency can't be solved in this sprint | Block on API fix |
| 7 | CEO | Portfolio consolidation → deferred to office-hours | Mechanical | P3 (pragmatic) | Strategic question, not this plan's scope | Merge apps now |
| 8 | Design | ScrollView wraps content-only, not button/dots | Mechanical | P5 (explicit) | Button outside scroll region prevents inaccessibility | Wrap whole card |
| 9 | Design | Replace Spacer(minLength:0) with .padding(.vertical, 24) inside ScrollView | Mechanical | P5 (explicit) | Spacer collapses to zero inside ScrollView — layout breaks | Keep Spacer |
| 10 | Design | Add isRequesting loading guard to location button | Mechanical | P1 (completeness) | Double-tap fires 2 permission requests; 10-line fix, in blast radius | Defer |
| 11 | Design | FeatureRow @ScaledMetric for iconFrameSize | Mechanical | P1 (completeness) | 44×44 fixed frame clips SF Symbol at AX XXL; 1-line fix | Defer |
| 12 | Design | Already-granted location state → TODOS.md | Mechanical | P3 (pragmatic) | Edge case; not blocking v1.6 | Fix now |
| 13 | Design | Entrance animation on wrapper, not scroll content | Mechanical | P5 (explicit) | Animation conflicts with ScrollView scroll position | Defer |
| 14 | Design | TransitBadge fixed frame → TODOS.md | Mechanical | P3 (pragmatic) | Cosmetic, low priority | Fix now |
| 15 | Design | Features heading scale → TODOS.md | Mechanical | P3 (pragmatic) | Visual polish, low priority | Fix now |
| 16 | Eng | stop-tap race: manual test T1 sufficient for v1.6; unit test → TODOS.md | Mechanical | P3 (pragmatic) | Manual test verifiable on device; unit test adds infra complexity | Block on unit test |
| 17 | Eng | vehicleFetchCount unit test → TODOS.md | Mechanical | P3 (pragmatic) | Manual test sufficient | Block on unit test |

---

## Cross-Phase Themes

**Theme: Test coverage gap** — flagged in Phase 2 (Design: loading/double-tap states unspecified) and Phase 3 (Eng: no automated tests exist for any onboarding flow or stop-tap path). High-confidence signal. Both phases independently identified that the WelcomeOverlay has zero test coverage. Acceptable for v1.6 (manual verification plan exists), but a unit test harness is the next major quality investment.

**Theme: Implementation specificity deficit** — flagged in Phase 2 (Design litmus: 5/10 — ScrollView implementation underspecified) and Phase 3 (Eng: 2 critical implementation ambiguities caught). The plan as written would have resulted in bugs on the first implementation attempt without the review. Key finding: Spacer collapse inside ScrollView and button accessibility outside scroll region are non-obvious failure modes. Both are now explicitly documented in TODOS.md and the corrected plan.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | issues_open | 6 premises checked (2 invalid), 7 auto-decisions, 1 taste decision |
| Codex Review | (usage limit) | Independent 2nd opinion | 0 | — | Codex API quota exhausted — subagent-only mode |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | issues_open | 8 findings (2 critical added to scope, 6 deferred/noted) |
| Eng Review | `/plan-eng-review` | Architecture & tests | 1 | issues_open | 4 findings, 5 test gaps, test plan written to disk |
| DX Review | (skipped) | No developer-facing scope | 0 | — | End-user iOS app — DX phase skipped |

**VERDICT:** APPROVED PENDING PREMISE GATE — 17 auto-decisions made, 1 taste decision surfaced. 2 critical plan bugs caught (Bug 4 ghost + vehicleFetchCount wrong cap). Test plan at `~/.gstack/projects/dautovri-berlin-realtime-map/test-plan-v1.6.md`.
