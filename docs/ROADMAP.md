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
