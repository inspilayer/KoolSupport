# KoolSupport 0.10.15-rc.1 — Development candidate (NOT published)

## New: KS Quest Checker

- Seventh optional KoolSupport module; one physical `KoolSupport/` install folder.
- Search quest names in the native Tools → Quest Checker UI (or `/kool quest`); exact numeric quest ID search.
- Shows a row for every matching ID, including same-name quests. Select any row to ask Blizzard's quest-completion flag whether that ID was turned in by this character.
- Search is case-insensitive with exact/prefix relevance; recent quest IDs are saved per character (up to 20).
- Bundled starter title: **The Prophecy of Mosh'aru**, ID **3527**.
- With separately installed **QuestieDB**, automatically indexes the game's full available QuestieDB catalog using its public read-only API. No mandatory QuestieDB dependency and no QuestieDB code/data redistributed.
- Without QuestieDB, uses locally known titles, titles available from the in-game quest log, and accessible completed quest names. **Name search coverage is limited** in this mode; direct ID checking remains functional.
- Completion states: **Completed / turned in**; **Not flagged completed** (could still be on the quest); **Unknown** if the client cannot supply a reliable flag.
- No quest acceptance, turn-in, log selection, network calls, player input automation, or secret-health access.

## Regression/compatibility

Preserves six existing tools, DIES native clipping, silver threat tap state, XP reminder, SavedVariables, spellbook/macros and the single addon TOC. CI must pass full Lua syntax/tests, one-root seven-module package and real BigWigs CurseForge-compatible packaging dry-run.

## Before Beta

Live Forever QA: open `/kool quest`; search `prophecy` and `3527`, select a row, verify against `/run print(C_QuestLog.IsQuestFlaggedCompleted(3527))`, test another uncompleted quest and unavailable status, try QuestieDB present/absent and module toggle. **Do not publish or overwrite the immutable v0.10.14-rc.1-beta.** Explicit owner approval is required for any new public tag.
