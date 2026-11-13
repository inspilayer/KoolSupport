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
| CurseForge release migration | **Beta 0.10.0 approved; unified 0.10.1 candidate** | All five modules in one listing; verify Forever live APIs and feature behavior before newer tag |

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

## Visual-style sprint — Modern KS default

- Native KS Afflictions gets selectable Modern KS (default), Classic WoW and Minimal layouts; 4 lethal indicator modes (DIES/skull/both/off); 4 DoT palettes; spell icons; per-frame lethal alerts; size and visibility toggles.
- Browser-only offline simulator updated for matching controls, colors and mock nameplates; simulated lethal checks are not proof of WoW API behavior.
- Offline tests extended for defaults, invalid enums, per-unit display gating and secret-health passthrough. CI must be green.
- Tracking engine remains untouched and credited under MIT.
- **Remaining:** live Forever check of status-bar clipping/font visibility, client textures and nameplate layering before release.

## 0.10.0-rc.1 class recommendation and publication milestone

- Added 45 class-specific quality-of-life templates across nine Forever classes to the bundled generic Macro Suite, without linking to the optional Support Sessions.
- Class/spell icons and learned spellbook readiness filtering; four tabs: Recommended, General, Custom, All. No automatic installation.
- Kept existing native macro conflict, edit-fingerprint and combat protections. Added optional native icon support for templates.
- Prepared software-only CurseForge description, changelog and exact two-directory standard ZIP package, alongside optional plugins.
- **Release readiness gate remains open:** check all live client APIs and class spell names, version/Interface, hand-edited-macro protection and SavedVariables migration; current candidate is Beta/RC, not a live-verified stable release.


## Distribution automation: tag-only native CurseForge packager

- Added .pkgmeta to package the Base + Macros siblings and omit optional plugins and development assets.
- Added CI tests to validate .pkgmeta and dry-run the BigWigs packager on every PR; no uploads in CI.
- CurseForge should be set to package tagged commits only. Beta tag names must contain beta.
- Outstanding: live client checks, manual review of a tagged release and observation of CurseForge's real generated file. No tag created here.

## Beta delivery automation (manual approval → automatic packaging)

Added user-initiated GitHub Actions workflow to verify and push an immutable `vVERSION-beta` tag from main only. It does not run on normal PR merges. Requires the owner to finish the external CurseForge GitHub push webhook setup in repository Settings; verify 2xx delivery and CurseForge file status when first used. Runtime gameplay/client compatibility remains unverified until real tests are completed.

## KS Stealth talent effects — Sprint 1

- **Implemented on feature branch**: opt-in read-only `Talent Impacts` page inside separately installed KS Stealth, initially Druid/Rogue. Hover and click a talent to see its affected ability list, a non-live tooltip-summary effect, and game spell textures when available.
- Initial Druid: Ferocity, Shredding Attacks, Savage Fury. Initial Rogue: Efficient Strikes, Coup de Grace, Puncturing Wounds, Flawless Execution. November 2 Rogue renames included; actual Forever talent/spell data requires launch-client verification.
- No trained ranks, stat/damage calculation, crit estimates, Blizzard talent-frame hooks, or spellbook annotation in this sprint. Existing combat nameplate resource HUD and user macro data stay unchanged.
- **Sprint 2 acceptance:** detect trained ranks and learned spell ranks read-only, demonstrate per-component computations (direct hits vs DoTs/cost), optional crit estimates with explicit assumptions, optional spellbook overlay, safe fallbacks and talent change refresh. Validate actual Blizzard APIs and combat/secret restrictions before native tooltip hooks.
- Beta distribution remains tag-only and deliberate; the Talent Impacts feature now belongs in the unified 0.10.1 package but should not trigger another CurseForge upload merely because this PR merges.


## 0.10.x launch plan — unified CurseForge suite

**Decision (Nov 3):** One KoolSupport CurseForge project, one installable ZIP containing Base, Macros, Support Sessions, Stealth and Afflictions (five sibling WoW AddOns directories). The previously approved `v0.10.0-rc.1-beta` remains unchanged. `v0.10.1-rc.1-beta` has also now been tagged via the GitHub Publish Beta Action; subsequent Talent Impacts work goes into `0.10.2-rc.1`; versioning stays within **0.10.x** through launch test and fixes.

**Ready for CI review:** `.pkgmeta`, `scripts/check.py`, and the upstream-packager ZIP validator now assert all five roots and the vendored DoesItDie MIT license/notice. The UI remains modular rather than creating separate CurseForge pages. Existing per-character settings and macro protections are retained. Existing standalone plugin ZIP outputs can be used for *developer isolation only*.

**Next (Nov 4 evening):** Install the unified development ZIP in Forever live; confirm Interface marker, five addon loads, controls in `/kool`, all class macro behavior, Druid/Rogue talent hover, nameplate secret safe-passthrough, Afflictions estimated DoTs, Support Sessions, saved settings after reload and no taint. Resolve any issues on new 0.10.x RC before manually approving a Beta tag. Only after successful tests, use GitHub's manual Publish Beta action to trigger a single CurseForge file through the already configured webhook. Do **not** automatically publish after CI merges; stable promotion also needs separate owner approval.


## KS Stealth Talent Impacts — Sprints 2 + 3 (Nov 3, 2026)

**Engineering implemented; live Forever validation still pending.** Sprints 2/3 extend the Druid/Rogue catalog to 6 Feral Druid and 10 Rogue talents, correct Flawless Execution (10 Energy), and incorporate the Nov 2 renamed/reworked Rogue Efficient Strikes, Coup de Grace and Aggression.

- **Sprint 2:** read-only trait walker using active `C_ClassTalents.GetActiveConfigID` + `C_Traits`, protected from unavailable API, pending uncommitted talents, unknown/secret ranks and combat. Read learned spellbook and choose highest captured spell rank, not first. Inspect `C_Spell.GetSpellPowerCost` only out of combat and only for a known active resource. Estimate cost without a talent by adding the documented reduction to the current observed cost; label it **approximate** because other effects can modify costs. Damage estimates use a **normalized 100 base**, never made-up real hits. Optional 200% baseline crit illustration (not an actual crit guarantee); crit chance shows percentage-point changes, not guaranteed extra crit damage.
- **Sprint 3:** expanded curated Druid/Rogue coverage and optional read-only native spell tooltip annotations via feature-detected `TooltipDataProcessor.AddTooltipPostCall`; `KSMacros` Full Spellbook shows `[KS talents]` markers when enabled. Added paged KS Talent UI with hover/click, trained rank status, spell rank and refresh. All functionality remains opt-in, ON only through `/kool`; annotations and crit illustrations have separate default-OFF switches. Tooltip callback never casts, selects combat abilities, or reads protected combat values.
- **Tests:** `tests/test_talent_resolver.lua` exercises trait ranks, staged-data refusal, highest learned rank, documented cost/normalized math, tooltip deduplication, out-of-combat gating and settings. Existing `test_talent_impact.lua` and `test_stealth.lua` retained and updated. Require Lua/full packaging CI plus the upstream five-module CurseForge dry-run before merge.
- **Release:** now `0.10.2-rc.1` source (0.10.1 tag already exists); no new tag or CurseForge file from merging. Previous `v0.10.0-rc.1-beta` immutable. Test Nov 4 evening in the live client: trait tree names/IDs, spell rank and cost API returns, talent changes, tooltip hook, crit math labels, visual layout and cache under reload/combat. Any mismatch is corrected in 0.10.x before publishing or stable promotion.

References: https://warcraft.wiki.gg/wiki/API_C_ClassTalents.GetActiveConfigID ; https://warcraft.wiki.gg/wiki/API_C_Traits.GetConfigInfo ; https://warcraft.wiki.gg/wiki/API_C_Traits.GetNodeInfo ; https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellPowerCost ; https://talentsforever.com/druid/talents ; https://talentsforever.com/rogue/talents/efficient-strikes ; https://talentsforever.com/rogue/talents/coup-de-grace .


## Sprint 4 — in-game Launch Checks / unified-suite readiness

Add a read-only `/kool` → Launch Checks screen to report client Interface marker, five addon loaded/registered/enabled states and the mere *presence* of spellbook, talents, tooltip processor, nameplate and combo-point API entry points. The page has explicit uncertainty labels and a manual Re-run action, no combat resource reads, no macro edits, no file/network access. Fix the stale Home wording that incorrectly implies only Base+Macros ship. Add an offline diagnostic UI/mock test. This is pre-launch instrumentation to assist Nov 4; **no API presence check is a claim of actual gameplay correctness or release approval**.

Next engineering hardening sprint: test and strengthen migration/idempotency and macro ownership with malformed or conflicting legacy SavedVariables and native macro fixtures. Keep `0.10.2-rc.1` untagged until user permits a new Beta and completes live checks.


## Sprint 5 — macro migration/ownership hardening

- Restrict v0.6.4 `owned + generated` migration to an explicit boolean true, existing safe name/body constraints, never modifying historical root tables. A malformed old draft order remains preserved and migration retryable, not normalized destructively.
- Guard native macro lookup, native body inspection and slot counting from errors/malformed returns. Unknown native state **must prevent writes**. Guard native create/edit calls, only update KS ownership after successful client result.
- Preserve batch **preflight** invariants (all collisions/slot counts evaluated before any changes); a native failure after part of a batch can still leave prior player-approved writes, which must be reported and is not fully transactional.
- Add mock regression fixture of malformed root SavedVariables, hand-edited macro, unrelated same-name macro, and API errors. Need real player backup fixture and in-client validation Nov 4 before stable promotion. No new tag on merge.


## Sprint 6 — unified load/startup smoke test

- Add a CI-run Lua cold boot that loads the entire one-project package in **actual five .toc file order**, including Afflictions vendor locales/tracker/bridge, using a single fake WoW runtime.
- Assert four module registrations, all pages, optional module toggles, dependence of Support Sessions on Macros, vendor namespace, no macro writes at load, and preservation of unrecognized player and tracker SavedVariables.
- Ensure both mock test CI and the upstream CurseForge five-folder dry-run pass before merge. This reduces pre-launch integration risk but does not validate live game behavior.


## Post-launch 0.10.3 RC: movable KS Afflictions Target/Focus HUDs (November 5)

- User-visible defect: Target DoTs appears in a prominent gameplay area with no way to drag it (observed on a real Forever screenshot). Approved `v0.10.2-rc.1-beta` is immutable and is not modified.
- Implementation: left-drag each unit HUD **title** outside combat; save separate screen offsets per character in `KoolSupportDB.modules.ks_afflictions.hudPositions`; reset Target and Focus independently in the KS Afflictions settings. The original unit-frame anchors remain defaults until manually moved. Nameplate HUDs remain anchored and non-draggable.
- Scope: display geometry and controls only. Tracking, secret-health passthrough, no automation, preserved previous saved preferences and third-party MIT engine remain unchanged. Unit HUDs are parented to `UIParent` and clamped to screen.
- Release: new `0.10.3-rc.1` development candidate only; CI mocks cannot prove exact Forever frame-scale or tooltip behavior. Test both drag handles, client reload persistence, combat lockout, target switching, UI scaling and reset in Forever before any new Beta tag (explicit owner approval required).


## 0.10.4 RC — opt-in simplified in-frame Target/Focus DoT mode

User reference from November 5 shows a health bar with purple estimated-DoT portion, spell icons above and a green `DIES` label beside it. A player should be able to choose `Simplified / On-frame` in KS Afflictions settings rather than reserve screen space for the separate draggable panel.

- **Done in source candidate:** `onFrame=false` per character until explicitly enabled. Resolve existing Target/Focus StatusBars through classic/modern built-in names, anchor separate mouse-transparent overlays, add a thin estimated DoT strip, up to 3 spell icons and the existing secret-safe lethal indicator, with explicit fallback to the movable panel when native bars are unavailable. Keep nameplates unchanged; native frame sizes, values and status bars are never modified.
- **Regression:** mocked health is opaque; only child StatusBars receive its values, existing native health bar does not. Toggle, missing bar fallback and swapping to another bar are covered; prior SavedVariables remain unaltered.
- **Still to validate in game:** native bar paths in Forever and with client UI addons; overlays do not suppress stock health text or click functionality; toggles and combat restrictions work; `/reload` persists preference; DIES clipping behaves as intended; high-contrast placement, focus and target alignment. Prior `v0.10.3-rc.1-beta` is tagged and immutable. No publishing without separate explicit approval.


### 0.10.4 settings accessibility follow-up (Nov 5)

- User screenshot confirms 0.10.3 in-game, so it cannot show 0.10.4's new simplified toggle. The initial 0.10.4 toggle was also visually buried near the bottom of a crowded Afflictions page.
- Move the ON/OFF toggle to the first-screen Target & Focus section with two tabs: Appearance & Colors, Visibility & Position. Retain scale/height/nameplate offsets, resets, existing style/color/lethal settings, and saved HUD behavior.
- Offline acceptance: each clickable UI control stays within Base's 824x605 content size; default tab, tab switching and direct on-frame toggle callback work. Live: screenshot both tabs at player UI scale, verify no cutoffs, then test in-frame rendering and fallback before approving another Beta.


## 0.10.5 RC — Campfire Chat (November 6, 2026)

**Owner-approved feature request**: Add a fun, random and wholesome optional Campfire Chat module to the one KoolSupport suite. Four player-clicked categories: Joke, Spooky, Ramble and Edgy Joke. The module must speak in nearby `/say` only while the player's `Campfire Nearby` buff is present.

- **Implementation:** six-folder packaging, independent `KSCampfireChat` module, live module/page gating, four clearly described buttons, original content (16 short, chat-safe, locally curated entries each, 64 total), shuffle bag, no-repeat behavior, 8-second cooldown, direct click only, buff spell ID 1283391, modern and legacy aura fallbacks, and no automatic channel broadcasts.
- **Defensive rules:** fail closed on unavailable or secret aura data; no client-wide chat monitoring, external services, timers, bots, macros, unattended or multi-client activity. Never bypass protected outdoor chat APIs. Do not create more than one `SAY` line per click.
- **Testing:** offline runtime tests for exact buff detection, unavailable API, wrong buff, no-sends on load/events, SAY-only, 240-byte maximum, cooldown, no repeats, module disabled, native GUI, and the six-folder packager. CI and manual inspection before merge.
- **Unfinished client gate:** test the player-buff API and click-to-SAY under current Forever game rules, especially with a real campfire and a second nearby player; observe /say throttling and buff disappearance. No new tag, public upload or stable claim without explicit approval. Tagged 0.10.4 is immutable.

## 0.10.6 RC — Lightweight tank nameplate threat colors (November 11, 2026)

User wants a minimal enemy health-bar threat modifier, avoiding ThreatPlates. Four categorical tank colors run from red when securely holding aggro, through pink and violet, to purple with little/no threat. This is not a smooth numeric gradient because Forever can conceal exact threat percentages.

Implementation: an optional KS Threat seventh sibling addon, disabled per character by default, with combat-only and purple-zero options. Resolve default enemy nameplate health StatusBars and overlay with a noninteractive health-synchronized display; leave Blizzard's original health/statusbar untouched. Detect status via guarded UnitThreatSituation calls; never inspect protected/secret threat numbers or perform arithmetic on secret health. Hide overlay if required APIs or native bars are missing. Event-driven, no perpetual frame polling.

Offline acceptance: colors for status 0–3; hostile/engaged controls; secret-value fallbacks; native bar unmodified; transitions, nameplate removal, disabled module, saved data unchanged, seven-addon packaging and cold boot. Live gate: test Druid tank on several mobs, gains/losses, combat entry/exit, threat-state mapping, target text and KS Afflictions/Stealth compatibility. No owner-approved release or tag yet.

## November 13, 2026 — 0.10.7 native nameplate compatibility and diagnostics

Player observation on tank: KS Threat 0.10.6 appears to make no visible changes. Source audit found a reproducible root-cause bug: KS Threat only used plate.namePlateUnitToken while native Blizzard nameplates expose plate.unitToken and plate:GetUnit(), exactly as the existing KS Stealth module already handles. The strict token gate therefore skipped ordinary Blizzard nameplates. Further potential client restrictions include unavailable/secret UnitCanAttack, UnitAffectingCombat, UnitThreatSituation, protected frame rendering or absent native health bars; these must remain safe and separately diagnosed rather than guessed about.

Implementation: 0.10.7 RC retains the original tank palette, default-off module and independent health overlays, but introduces a safe native unit-token fallback chain, additional health bar shape, UNIT_HEALTH / UNIT_MAXHEALTH refresh, and a player-clicked Diagnose visible plates button listing aggregate skipped reasons without logging unit names, IDs, health, threat values or secret data. Extend regression mock to reproduce the missing namePlateUnitToken and confirm both unitToken and GetUnit() work.

Release gate: full tests, seven-addon package, in-client test with visible enemy nameplates and engaged mobs. No auto-release: 0.10.6 Beta is tagged; 0.10.7 is a new unpublished candidate. If the diagnostics show threat unavailable while engaged, investigate the client API rather than disabling secrecy checks.


## November 13, 2026 — 0.10.8 single-root packaging migration

**User request:** clean up the AddOns directory so KoolSupport is one installable root folder rather than seven separate siblings. This is a structural packaging and game-loading change, **not** a rewrite of six features.

- **Implementation:** one `KoolSupport/KoolSupport.toc` loads Base and six groups from `KoolSupport/Modules/{KSMacros,KSSupportSessions,KSStealth,KSAfflictions,KSCampfireChat,KSThreat}` in unchanged order; source modules remain separated for unit testing. The source package builder and CurseForge `.pkgmeta` both produce that identical single-root layout and remove nested `.toc` files from the distributed ZIP.
- **Integrity:** no existing in-game module IDs, dependency gates, features or per-character `KoolSupportDB` keys change. Offline boot tests use the single TOC and shared namespace to exercise module registration and vendor initialization. Diagnostics inspect registration rather than nonexistent physical sibling addon states.
- **Migration:** WoW cannot load module TOCs nested two directories deep. Users must remove six obsolete sibling addon folders before extracting the unified ZIP, otherwise code may be loaded twice. `KSAfflictionsTrackerDB` is a separate account-wide global that WoW persists by addon folder name; the new unified TOC declares it, but the existing tracker file must be copied or merged *with WoW closed* to preserve prior learned data, never overwritten automatically. Keep backups of AddOns/WTF.
- **Testing:** validate every TOC script has a matching packaged file, the exact single root, no child TOCs, retained tracker license, one namespace and unchanged feature gating; the **actual** CurseForge packager must produce a single-root ZIP, not just the Python dev ZIP. Confirm the migrated game launches in Forever without duplicate registrations before any new public Beta tag.
