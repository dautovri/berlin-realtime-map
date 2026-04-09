
# Berlin Transport Map — Claude Code Instructions

See `.github/copilot-instructions.md` and `AGENTS.md` for Swift/SwiftUI conventions.

## Quick Reference

- **Stack**: Swift 6.2+ / SwiftUI / iOS 26.0+
- **ASC App ID**: 6761736286
- **Build**: `xcodebuild -project BerlinTransportMap.xcodeproj -scheme BerlinTransportMap -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
- **Mandatory**: Project must compile after every change

## Key Architecture

- Real-time Berlin public transport visualization on Apple Maps
- Live GTFS-RT feed integration
- @Observable view models with @MainActor

## Business Context

- Part of portfolio — Berlin-focused transit apps
- Companion to MyStop Berlin

## gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

Available gstack skills: /office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review, /design-consultation, /design-shotgun, /design-html, /review, /ship, /land-and-deploy, /canary, /benchmark, /browse, /connect-chrome, /qa, /qa-only, /design-review, /setup-browser-cookies, /setup-deploy, /retro, /investigate, /document-release, /codex, /cso, /autoplan, /plan-devex-review, /devex-review, /careful, /freeze, /guard, /unfreeze, /gstack-upgrade, /learn

## Skill Routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.

- Product ideas, brainstorming → office-hours
- Bugs, errors → investigate
- Ship, deploy, create PR → ship
- QA, test → qa
- Code review → review
- Architecture review → plan-eng-review