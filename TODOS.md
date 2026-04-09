# TODOS

## WelcomeOverlay / Onboarding

### P2 — Followup

- **WelcomeOverlay: Add ScrollView wrapper for Dynamic Type / landscape resilience**
  Deferred from v1.5 plan. The current Spacer-based layout may clip on iPhone SE or under very large Dynamic Type. Wrap each page VStack in a ScrollView with `.scrollBounceBehavior(.basedOnSize)`.
  **Deferred from plan:** PLAN.md (v1.5)

- **WelcomeOverlay: Version the `hasSeenWelcome` key**
  Current key is `"hasSeenWelcome"`. If onboarding content changes significantly, rename to `"hasSeenWelcomeV2"` so existing users see the new content.
  **Deferred from plan:** PLAN.md (v1.5)

- **WelcomeOverlay: Staggered feature row animations**
  `featureRow` previously accepted a `delay` parameter that was unused (removed in v1.5). To implement true stagger, give each row its own `appeared` state or use individual `.animation(.spring.delay(n))` modifiers.
  **Deferred from plan:** PLAN.md (v1.5)

## TransportMap

### P2 — Followup

- **Stop-tap async race fix**
  Tapping stop A then stop B before A's network response arrives causes A's response to overwrite B's sheet data. Fix: tag each request with the stop ID and discard responses that don't match the current selection.
  **Deferred from plan:** PLAN.md (v1.5, Codex-only find, marked not in scope)

- **`vehicleFetchCount` unbounded growth**
  `vehicleFetchCount` in `TransportMapView` increments on every fetch and is checked against a threshold to trigger review requests. No cap — over time, the counter grows past 20 and the review prompt never fires again. Cap at 20 or switch to a time-based trigger.
  **Deferred from plan:** PLAN.md (v1.5)

## Favorites

### P2 — Followup

- **Route replay implementation**
  Saved routes currently show a "Route Replay Unavailable" alert. To implement: store departure/arrival times and leg details in the Favorite model, then recreate the route object from stored data on tap.

## Completed

- **First-launch welcome overlay (3 screens)** — Completed v1.5 (2026-04-09)
- **tvOS compatibility guards** — Completed v1.5 (2026-04-09)
- **Route favorites silent failure fix** — Completed v1.5 (2026-04-09)
- **Location auto-center on first grant** — Completed v1.5 (2026-04-09)
- **VoiceOver accessibility hint fix (route favorites)** — Completed v1.5 (2026-04-09)
