# KoolSupport engineering roadmap

**Updated 2026-11-03.** Stages are independent of fixed version numbers. Do not infer completion from a proposed release label.

| Priority | Stage | Status / acceptance gate |
| --- | --- | --- |
| 0 | Repository + handoff discipline | Initial main README, foundation branch and mandatory PR handoff template established. |
| 1 | Modular Base + bundled KS Macros foundation | **Implemented as 0.7.0-dev scaffold**; Lua tests and packaging; not yet an upgrade from monolith. |
| 2 | Existing KS Macros feature parity | **Not done**: migrate v0.6.4 Macro Suite, Custom Builder command library, Spellbook scanning, saved drafts, safe installer, UI and tooltips. |
| 3 | Per-character SavedVariables migration | **Not done**: idempotent, tested preservation of generated macros, fingerprints, drafts, user settings and supportee selection. |
| 4 | KS Support Sessions optional child | **Not done**: class-aware profiles, named focus, follow/mobility, healer utility and resurrection, plugin-gated UI. |
| 5 | KS Macro Profiles optional child | **Not done**: versioned JSON copy/paste import-export, schema validation, review, shareable suite, integrity limits. |
| 6 | KS Stealth independent addon | **Not done**: informational combo-point UI and safe user-triggered macro templates. |
| 7 | Live client and CurseForge verification | **Blocked** until actual WoW Forever access and moderation outcome. |

## Current next action

**Preserve v0.6.4 functionality before calling the modular build production-ready.** Bring the last verified monolithic source into a clearly marked legacy reference path, repair existing tests with portable paths, then migrate the generic Macros functionality. Review migration and saved-variable compatibility before touching Support Sessions.

## Every PR

- Update `docs/CHAT-TRANSITION.md` with verified state, changes, tests and next steps.
- Review this roadmap, capture any new user product decisions, identify migrations.
- Verify test results; do not claim game-client or CurseForge tests without evidence.
- Preserve the separate 0.6.4 review artifact until explicitly replaced after testing.
