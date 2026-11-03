# KoolSupport engineering roadmap

Updated 2026-11-03. Development labels are not release promises.

| Stage | Status | Remaining acceptance gate |
| --- | --- | --- |
| Repo, base registry, handoff CI | Complete on `main` before this sprint | Verify PR CI after new merge |
| Generic KS Macros pages | **0.8.0-dev implementation**: generic suite, learned spellbook, grouped builder | Forever UI smoke test, compare old v0.6.4 edge cases and builder coverage |
| Non-destructive legacy migration | **0.8.0-dev tested offline**: drafts, ownership fingerprints, session prefs | Real SavedVariables fixture from running client and collision tests |
| KS Support Sessions optional child | **0.8.0-dev implementation**: legacy healer presets, named focus setup, install delegation | Live class/spell syntax, UI parity, manual macro slot use and first-run testing |
| KS Stealth optional sibling | **0.8.0-dev shell and visible-nameplate indicators** | Live confirmation of target-bound combo points for all visible nameplates, secret-value compatibility and API events |
| KS Macro Profiles optional child | Not started | Versioned JSON import/export, validation and user-reviewed merge |
| CurseForge release migration | **Blocked**: existing v0.6.4 review candidate frozen | Feature parity, actual client verification, approval of a new release |

## Immediate next work after this PR

1. Verify CI and reconcile any discrepancies in client API availability or secret restrictions; don't merge unreviewed changes.
2. Test 0.8.0-dev in actual Forever client when access is available: native macro create/edit, nameplate target switching, module toggles, known spellbook scanning, UI pages, SavedVariables persistence.
3. Compare generic Macro Builder with archived v0.6.4 `Studio.lua`, especially its full condition and item-command palette and flyout scanning. Close parity gaps without recreating the monolith.
4. Confirm migration on a copy of real v0.6.4 SavedVariables and test manual edits/non-owned macro name conflicts.
5. Add KS Macro Profiles only after the core APIs stabilize.
6. Keep handoff, roadmap, release notes, and packaging current with each substantive PR.


## New 0.9.0-dev development sprint — KS Afflictions

- **Implemented on feature branch:** optional `KSAfflictions` addon with the modified upstream MIT DoT/tick engine, KS-native target/focus/nameplate bars, basic toggles, size/offset controls, native tooltip data, and optional lethal indicator.
- **Shared UI:** Base `BarTheme.lua` defines bar palette; no duplicate standalone DoesItDie UI or /did commands.
- **Browser:** standalone, offline simulated preview for options, DoT ticking, multi-nameplate rendering, lethal indicator and mock player-target selection.
- **Tests:** new `test_afflictions.lua` includes opaque health passthrough; package script checks third-party license and creates optional ZIP. CI must pass before merge.
- **Outstanding:** real Forever event/secret-health compatibility and DoT attribution. Validate against live targets before any release. Track defects in follow-up PRs rather than weakening the release gates.


## Post-PR #5 shared bar polish

PR #5 merged (squash `9eff27c8f31b8d02f4879160ddfd1da89bf6437c`) after passing the 0.9.0-dev CI suite and a supplementary vendor-tracker cold-boot smoke. KSAfflictions is development only; live Forever validation remains a release gate.

KS Stealth now uses the shared `KoolSupport.BarTheme:StyleBar` palette for its combo-point segments, with a safe fallback for isolated mocks/clients. The visual foundation is shared; a future settings panel may expose cross-module bar presets after actual client testing.
