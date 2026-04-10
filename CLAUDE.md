
## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health

## Design System

The project uses **Berliner Precision** — see `DESIGN.md` for the full spec.

Key rules for all SwiftUI work:
- Status colors: `#00A550` on time, `#E8641A` delayed, `#C41E3A` cancelled, `#6B4E9E` service change, `#8A8A8E` stale
- Departure times and counts: always `.monospacedDigit()`
- Station names: always `.fontDesign(.rounded)`
- Spacing: 8pt base grid (8 / 16 / 24 / 32 / 48)
- Animations: respect `@Environment(\.accessibilityReduceMotion)`
- Line badges: authentic VBB/BVG colors only — never approximate
- No hardcoded font sizes except the hero ETA (42pt bold monospaced in departure sheets)