## What changed

Describe the player-facing behavior and engineering change.

## Verification

- [ ] `python scripts/check.py --package` passed (with Lua available for runtime tests).
- [ ] Existing behavior was tested or explicitly identified as pending migration.
- [ ] Macro writes remain player-initiated, out-of-combat, and manual-edit-safe.
- [ ] Plugin dependencies and SavedVariables compatibility were considered.
- [ ] No claims of live WoW Forever testing without real client evidence.

## Engineering handoff — mandatory

- [ ] **Updated `docs/CHAT-TRANSITION.md` in this PR.**
- [ ] Documented verified version, current state, migrations, known limitations, and next engineering step.
- [ ] Updated `docs/ROADMAP.md` when scope/status changes.

> Each substantive PR must carry its own handoff update. A change to code without handoff updates is incomplete.
