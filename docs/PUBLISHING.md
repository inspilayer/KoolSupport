# KoolSupport release and publishing workflow — 0.10.x

**Current CurseForge-approved Beta:** `v0.10.2-rc.1-beta` (owner-confirmed November 4, 2026). GitHub Publish Beta run `41826003702` succeeded after run `41818111040` encountered a transient GitHub Internal Server Error pushing the tag. Live Forever launch-client validation remains pending. **Do not rerun this release or overwrite its immutable tag.** Any post-launch fix requires a new version and separate approval.

## One CurseForge listing / one ZIP

KoolSupport's single CurseForge project (ID **1780256**) distributes the **entire suite** in one install. Players do not need separate CurseForge listings or downloads for Support Sessions, Stealth or Afflictions. Keep WoW's modular architecture: every `.toc` addon lives as a sibling folder directly inside `Interface/AddOns`.

The tagged-commit CurseForge packager uses root `.pkgmeta` to create:

    KoolSupport/
    KSMacros/
    KSSupportSessions/
    KSStealth/
    KSAfflictions/

Each is a loadable WoW addon with explicit dependencies; the in-game `/kool` Module Manager can enable/disable the optional components. KS Stealth's **Talent Impacts** page is independently opt-in (off by default). Afflictions retains Joe Greive's original MIT `Vendor/LICENSE` and `Vendor/NOTICE.md`.

`scripts/check.py --package` also creates a `KoolSupport_CurseForge_Standard_0.10.1-rc.1.zip` with the same five folders. Single-plugin and Base+Macros ZIPs remain *developer isolation/test artifacts only*. **Do not upload them as separate CurseForge projects, or as alternative files to the single-suite listing.** GitHub's main publishing path is tag-only, via the CurseForge packager, rather than manual ZIP uploads.

## Existing approved public Beta

Previously published `v0.10.0-rc.1-beta` contains only Base + Macros. It stays untouched; tags and CurseForge versions are immutable checkpoints and do not retroactively pick up merged source.

## Previous candidate: 0.10.1-rc.1 (already tagged)

The original unified-bundle PR used `0.10.1-rc.1` and the owner has since tagged it as a Beta; **not stable**. Talent Impacts Sprints 2/3 are `0.10.2-rc.1` on the next mainline. Stay within 0.10.x until live Forever launch validation and fixes on or after November 4. No version tag should be pushed merely because a PR was merged; the webhook only packages tag pushes. CI alone does not prove WoW client compatibility.

### Pre-release smoke test

1. Review green GitHub PR + main CI: `python3 scripts/check.py --package`, `python3 scripts/check_curseforge_packaging.py`, and the real `BigWigsMods/packager@v2 -d` ZIP validator. Inspect exactly the five siblings, `.toc` files, vendor license and notices.
2. Confirm Forever live Interface version; `16001` is the current development assumption.
3. Back up existing `Interface/AddOns` folders and `WTF` SavedVariables. Don't overwrite hand-edited native macros or player data.
4. Install all five sibling directories from the **development** standard ZIP into the live Forever addon path and check that all dependencies load. No extra nested KoolSupport folder.
5. On supported class(es), open `/kool`: confirm the Module Manager toggles, Macro Suite 45 class presets, active learned spellbook, custom draft/builder, explicit install/overwrite rejection; check Support Sessions focus macro previews and safe manual installation.
6. Test Rogue/Druid KS Stealth nameplate combo bars (multiple visible nameplates, switching targets, zero points, combat and secret values). Test Talent Impacts OFF by default then ON, hover/click, spell icons and persistence across reload.
7. Test KS Afflictions actual DoT tick attribution, target/focus/nameplate display, lethal clipping, UI styles, vendor tracker SavedVariables and changes under `/reload`. If display/API fails, disable the affected module.
8. Report Lua errors, screenshot actual Forever UI, check combat lockdown and no automated casts or targeting. Test a safe rollback using the backed-up addon and WTF folders.

### Manual publish workflow for a FUTURE version (0.10.2 already tagged)

1. In CurseForge project **1780256**, keep **Automatic Packaging: tagged commits only**, not Package all commits.
2. Keep the existing GitHub `push` webhook active and token private. The previous Beta tag verified the delivery flow.
3. Open `https://github.com/inspilayer/KoolSupport/actions/workflows/publish-beta.yml`.
4. Choose **Run workflow** on `main`, tick the explicit release checkbox, and run only after launch smoke-test approval. It reruns all source checks and upstream packaging dry run and creates a NEW versioned tag from a version-bumped check script after approval; do not reuse 0.10.2. The action refuses duplicates or a moved main branch.
5. Inspect GitHub Webhook **Recent Deliveries** for the new version's tag and 2xx status; then CurseForge Files for the new Beta package and moderation result.
6. Publish `docs/RELEASE_NOTES_0.10.2-rc.1.md` and update project description from `docs/CURSEFORGE_DESCRIPTION.md` when ready. Approval and discoverability remain controlled by CurseForge.

The GitHub `GITHUB_TOKEN` pushes the tag; the **external webhook** is the delivery path, not a recursively triggered GitHub workflow. Do not paste CurseForge API tokens into issues, documentation or chat.

## Rollback / safety

If launch testing fails, stop release, disable the problem module (or disable the corresponding WoW addon folder), restore backed-up `Interface/AddOns` and `WTF` when appropriate, and fix the issue in a new 0.10.x candidate. Do not reuse/force-move existing release tags. Standard releases require positive live validation and project-owner approval; Beta labels are not proof of successful in-game behavior.

Do not represent browser simulations as in-client screenshots. Retain MIT upstream notices and honor Blizzard secure restrictions.


## Next candidate — 0.10.5 Campfire Chat (Nov 6, 2026)

The successful GitHub `v0.10.4-rc.1-beta` tag is an immutable previous release. **Never re-run or retag it.** The next source candidate is `0.10.5-rc.1`, with six sibling addon folders (including `KSCampfireChat`) in the same CurseForge project 1780256. Publishing is still a **manual user-approved tag workflow**, with no tag generated by PR merge or normal CI. Require a real Forever campfire buff check, hardware-click /say test and no extra chat after buff loss before authorizing the next Beta.

## 0.10.6 candidate: KS Threat (November 11, 2026)

The public v0.10.5-rc.1-beta GitHub tag already exists and must never be changed or recreated. Candidate 0.10.6-rc.1 includes a seventh sibling, KSThreat, in the same CurseForge project 1780256, not a separate listing. Publish only after verifying red/pink/violet/purple threat states on a live Forever Druid tank, nameplate compatibility and full CI, followed by explicit owner authorization of a NEW versioned beta tag.


## 0.10.8 RC — one folder on disk (current packaging specification)

Older sections above describe the previously released multiple-sibling-folder format; **this is superseded for 0.10.8 and later.** The new unified CurseForge project remains one listing, but the actual archive must contain only `KoolSupport/` at its root, with `KoolSupport.toc` and exactly six code directories under `KoolSupport/Modules/`. Unlike the past versions, no standalone `KSMacros.toc`, `KSAfflictions.toc`, etc. is distributed. The `.pkgmeta` nested destinations, `scripts/check.py --package` ZIP and BigWigs real packager dry-run are all checked for that exact shape; any packager placing modules beside KoolSupport instead of inside it is a release-blocking failure.

To upgrade from earlier betas, stop WoW, back up AddOns and WTF, remove **only** the old root-level `KSMacros`, `KSSupportSessions`, `KSStealth`, `KSAfflictions`, `KSCampfireChat` and `KSThreat` addon folders, then extract the ZIP's `KoolSupport/`. Per-character `KoolSupportDB` remains as-is. Copy account-wide `WTF/.../SavedVariables/KSAfflictions.lua` to `KoolSupport.lua` *only if absent*, or manually merge the `KSAfflictionsTrackerDB` assignment after backing up both. The old file is not deleted automatically. The tracker is now saved under the single addon root; this transition cannot migrate silently using a WoW API. Previous releases and tags remain unchanged.

The last publicly verified Beta tag at sprint start was `v0.10.6-rc.1-beta`; there is no 0.10.7 tag. `0.10.8-rc.1` is a separate unpublished candidate and needs a fresh owner-approved workflow after green CI and live Forever verification. Never retag earlier versions. CurseForge's external tag webhook remains the delivery route.


## 0.10.11 RC — group tap status overlay

0.10.11 adds a new silver override for mobs tagged outside the player's group, based on guarded Forever `UnitIsTapDenied`. It is included within `Modules/KSThreat` under the **single** installable `KoolSupport/` root. Full Lua tests, real BigWigs packager dry run and client smoke test of tagged outsiders/group-owned units are required before any separate owner-approved Beta publishing workflow. The merge does not dispatch a public tag or upload CurseForge files. All previously released tags remain immutable.


## 0.10.12 candidate — centered DIES compatibility

The 0.10.12 candidate extends KS Afflictions centered DIES to prewarm hidden health-bar text and support two native `UnitHealthPercent` curve visual sinks, with exact-GUID public maximum HP caching to make strict lethal thresholds available after combat starts. It does not modify the vendor tracker, game UI health, secrets, saved user preferences, or the six-module single-root package. Require full Lua, native-curve mock, single-root BigWigs packaging dry run, and actual Forever client validation (which can still legitimately hide DIES when no safe max/secret API is present). **No Beta tag or CurseForge publish without explicit owner approval.**


## 0.10.13 candidate — Base Time Since XP (November 15, 2026)

This source-only RC adds a **Base** last-XP activity reminder; the package still has **one** root `KoolSupport/`, one root TOC and **six** optional nested modules. Add `XPReminder.lua` after Core in the manifest; no changes to CurseForge listing, dependency graph, third-party vendor license, or existing module SavedVariables. Character preferences are stored additively in Base and default enabled, session reminders are 15-minute local messages only. Require CI Lua tests, one-root development ZIP, real BigWigs dry-run, and Forever live test to validate player XP event timing, max-level suppression and presentation. Do not auto-publish or reuse any prior public tag.


## 0.10.14 RC — DIES actual-client regression recovery

This RC repairs the screenshot-confirmed `max_baseline_unavailable` silence for centered DIES, using the native clipped StatusBar technique of MIT DoesItDie (Joe Greive), applied to text-only output on original target/focus/nameplate bars. It no longer depends on nonsecret UnitHealthMax for secret HP. All code still respects Forever's forbidden secret arithmetic and comparisons. Preserve one physical `KoolSupport/` addon folder with six bundled modules and the Base XP reminder; do not publish to CurseForge until the PR and main Lua/real BigWigs package checks pass **and** a player validates with visible DoT damage and HP falling below the threshold in the live game. Existing tags are immutable; manual owner approval for new Beta remains necessary.


## November 17, 2026 — version-parser fix after failed 0.10.14 Beta dispatch

The owner confirmed centered DIES works in Forever and explicitly authorized a **0.10.14-rc.1 Beta**. Initial dispatch run [44109728154](https://github.com/inspilayer/KoolSupport/actions/runs/44109728154) failed only during tag creation because the previous sed parser expected `VERSION='...'` and `scripts/check.py` contains `VERSION = '0.10.14-rc.1'`. There was **no new Beta tag** created by that attempt. The Node/Ubuntu warnings did not cause the failure.

Release workflow now calls `python3 scripts/release_version.py`, a validated Python AST reader. CI tests spacing, quoted string styles, the current release manifest and invalid/duplicate version cases to catch future failures before running the tag step. After the fix merges, initiate a **new** manual Beta workflow run on **main**, check the explicit approval checkbox and verify the tag `v0.10.14-rc.1-beta` is created. Do not use `Re-run failed jobs` on the earlier revision; GitHub Actions reruns may retain the workflow code from the failed commit. The external CurseForge webhook may then import the tag; verify the CurseForge project separately before claiming the Beta is publicly available. Do not rewrite any earlier tag.


## 0.10.15 Quest Checker candidate (November 19, 2026)

This is an **unpublished development RC**, adding seventh optional module KS Quest Checker into the existing single physical KoolSupport folder; no independent CurseForge project or separate install. It uses no embedded third-party QuestieDB content; optional runtime integration with separately installed QuestieDB is not a formal dependency. For broad searchable quest names, install an appropriate compatible QuestieDB build; without it, only locally known/game-known names and numeric IDs are available. Before publication require green Lua and packager checks, on-client 3527 complete/incomplete comparison, fallback with QuestieDB disabled, UI click and module toggle verification, and fresh owner approval. **Never regenerate or retag the already-published v0.10.14-rc.1-beta tag.** GitHub tag webhook HTTP 200 is not proof of a CurseForge file being available.
