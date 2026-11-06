# KoolSupport — Principal Engineer Chat Transition

**Canonical source:** `https://github.com/inspilayer/KoolSupport/blob/main/docs/CHAT-TRANSITION.md`  
**Repository:** `inspilayer/KoolSupport`  
**Last updated:** 2026-11-03  
**Purpose:** reusable across versions and new ChatGPT conversations. Never create per-version transition files. Every substantive PR must update this exact path.

## Startup instructions for every new engineering chat

1. Read this file directly from **current main** and verify the latest commit, PRs, CI, version, `.toc` manifests, and source tree. Do not assume this snapshot is current.
2. Read `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, all relevant Lua and tests, and inspect any open PR/branch before coding.
3. Treat the user as product owner with programming experience but limited Lua expertise. Act as principal engineer responsible for architecture, implementation, tests, packaged artifacts and risk assessment. Be candid about client-only verification.
4. Implement changes on a feature branch and open a focused PR. Every substantive PR **must edit this handoff**, with accurate version/checkpoint, current tests, migrations, risks, and concrete next steps. CI rejects PRs that omit this document.
5. Never silently overwrite or remove user SavedVariables, native macros, existing functionality, or the frozen CurseForge candidate. No changes to main/release unless requested or following established PR workflow.

**Reusable new-chat prompt:**

> Act as principal engineer for KoolSupport. Read `docs/CHAT-TRANSITION.md` from current `main` in `inspilayer/KoolSupport`; inspect the latest source, roadmap and PRs. Continue the project, preserving macro ownership protections, saved data, optional plugin dependencies, and Blizzard secure-action restrictions. I own the player vision; you own engineering, implementation, testing and packaging. Keep this handoff updated in every substantive PR.

## Product identity and approved module hierarchy

KoolSupport is a generic WoW macro-building platform, not a keyboard tool or multibox automation system. Built-in and optional features must be presented with conventional WoW-style UI (metallic frame, dark panels, gold labels, readable spacing); browser preview is only a mockup.

```text
KoolSupport Base                 REQUIRED, bundled
└── KS Macros                    REQUIRED, bundled ON by default
    ├── KS Macro Profiles        OPTIONAL, requires Macros (not implemented yet)
    └── KS Support Sessions      OPTIONAL, requires Macros (healing/focus/follow)
KS Stealth                       OPTIONAL, requires Base (Macro integrations optional)
Future KS modules                separate folders and versioned APIs
```

Each module uses a sibling `Interface/AddOns/` folder and `.toc` dependencies; logical nested UI is not a nested filesystem hierarchy. Base registers pages dynamically and gates disabled modules. Disabled modules' Lua remains loaded until UI reload.

## Verified mainline checkpoint — 2026-11-03, 0.8.0-dev

**Mainline verification:** PR #3 merged on 2026-11-03 as squash commit `a91410a276d3b0cf2385ea1e09d712f7d9d15888`. GitHub Actions (`lua` job on PR #3) passed with conclusion `success`. This is still **development**, not a published CurseForge upgrade. Always verify current main for newer commits.

- Archived the exact original monolithic v0.6.4 Lua source under `legacy/v0.6.4/` **for migration reference only**, omitted from install ZIPs. Its former CurseForge submission remains under review per the user and must stay untouched.
- Base UI now discovers registered pages, presenting Home, Modules, generic Macro Suite, Full Spellbook, Custom Builder, and optional plugin pages.
- **KS Macros** owns generic templates and saved drafts, learned active spellbook scanner (`C_SpellBook`), grouped command builder, and existing safe native macro installer. No supportee/healer preset UI here.
- **KS Support Sessions**, separate optional addon `addons/KSSupportSessions`, depends on Base + Macros. Reuses actual original v0.6.4 healer templates and provides user-selected supportee, named `/focus`, `@focus` heals and `@focustarget` offense, manual follow/mobility, utility and resurrection. Delegates writing to `KSMacros:Install` and does not run gameplay commands itself.
- **KS Stealth**, separate optional addon `addons/KSStealth`, depends only on Base, with soft Macros dependency. Has own settings and a nameplate HUD that attempts to draw 5 target-specific combo-point segments on every **visible nameplate** via `GetComboPoints("player", nameplateUnit)` -> `StatusBar:SetValue` with NO numeric comparisons in Lua. No off-screen enemy enumeration or automatic finisher choice.
- Native macro safety: max 255-byte body, conservative 16-byte name, `#showtooltip` first, out-of-combat explicit clicks only, existing name and hand-edit ownership checks.
- Legacy migration: `customDrafts` and `customOrder` copy into namespaced Macros storage idempotently; only trustworthy old `owned + generated` pairs become new ownership fingerprints. Support Sessions copies missing supportee/recipient/spec preferences; original root tables are retained and remain authoritative fallback for old class profile choices.
- Distribution: standard `KoolSupport_Base_Macros_0.8.0-dev.zip`, optional `KSSupportSessions_Plugin_0.8.0-dev.zip` and `KSStealth_Plugin_0.8.0-dev.zip`, and all-module development ZIP. Do not distribute as the next CurseForge release without client validation.

## Tests that have actually run

- Python `scripts/check.py --package`: validates all `.toc` manifests/source, dependencies, version labels, and builds separate ZIPs.
- Lua syntax: 13 addon Lua files loaded for syntax verification under local `texlua` (Lua 5.3). GitHub Actions ran Lua 5.4 and passed for PR #3.
- Offline mocked Lua tests: `test_core.lua`, `test_macros.lua`, `test_modular_split.lua`, `test_spellbook.lua`, `test_stealth.lua` passed in the local build. Tests cover dependency toggling, source separation, idempotent migration, macro protection, spellbook exclusions, multiple nameplate unit tokens, opaque combat resource passthrough, event cleanup, and combat setting restrictions.
- **Not tested:** actual Forever gameplay, real client tooltips/frames, non-current-target `GetComboPoints` access, in-game native macros, savedvariable migration with a player-produced live snapshot, CurseForge approval. Treat these as release blockers.

## Known issues / integration cautions

- WoW Forever uses modern *secret value* restrictions. **Never** compare, count, branch on, inspect, format, stringify, or use combo points to select a protected ability in Lua. Only pass returned values into supported visual sinks. This may or may not render for non-current nameplates; add a fail-closed fallback and obtain real client evidence.
- Nameplate iteration finds only visible `C_NamePlate` units; it is not a range/radar API. Filled pips are invisible at zero; no Lua condition reveals which enemy has points.
- The generic builder currently has a useful grouped command palette but still needs detailed parity comparison with the archived 0.6.4 `Studio.lua` (including flyouts, advanced modifiers, and tooltip polish). The current branch is **not** a full v0.6.4 replacement.
- Interface `16001` is the last known Forever beta marker; re-verify it with the active client before release. Spellbook API signatures and UI tooltip secrets need live testing.
- Support Profiles include class/talent-dependent spells, not a promise every spell is learned. Their macros require explicit key presses and remain subject to native casting rules.
- Archive `.toc`/old version strings are intentionally unchanged and do not represent the current modular dev version.

## Engineering governance

- No auto-casting, unattended follow, input broadcasting, target-based finisher selection, secure API bypasses or arbitrary outside-combat gameplay effects.
- Never delete unknown keys in `KoolSupportDB`. Test migration idempotence, old ownership records and user hand-edits before installing over v0.6.4. The old CurseForge ZIP remains untouched until explicit migration signoff.
- Tests and source reports must use actual tool results, not optimistic claims. Add tests for new features and update both this document and roadmap on every substantive PR.
- Keep standard install ZIP free of legacy source, screenshots, documents and tests. Optional plugins distributed separately, with dependency instructions.

## Next sprint after this PR

1. Check current main SHA and newer PRs. PR #3 is merged; its 0.8.0-dev source has not been live-client validated.
2. Use the real Forever client when accessible to test the new UI, native macros, secret values on several nameplates (including when target changes), support profiles and SavedVariables persistence.
3. Complete parity comparison with 0.6.4 generic Custom Builder and Spellbook flyout/tooltip features without recombining Support Sessions into Macros.
4. Validate SavedVariables migration with an actual backed-up v0.6.4 character before recommending an in-place upgrade.
5. Add versioned JSON Macro Profiles as a separate optional child only after the shared macro APIs stabilize.
6. Release only after user approval, live testing and a fresh CurseForge policy review.


## Engineering checkpoint addendum — 2026-11-03: KS Afflictions / 0.9.0-dev

**Project owner request:** Integrate swirllyman/DoesItDie under KoolSupport with fewer separate addons, coherent KS-style bar customizations, appropriate licensing and a browser-based UI/feature preview before the Forever client returns November 4. The prior 0.8.0-dev files and frozen CurseForge monolithic v0.6.4 submission must not be overwritten.

**Feature branch:** `feature/ks-afflictions-doesitdie-mit-090`; verify exact PR, status and main SHA at startup. No claim of live client verification.

**Design & ownership:** `KSAfflictions` is an optional Base-only module and installs in one sibling AddOns folder. It bundles a modified *tracking-only* copy of DoesItDie by Joe Greive (MIT); original license/copyright retained in `addons/KSAfflictions/Vendor/LICENSE`, with details in `Vendor/NOTICE.md`. Source repository MIT license is added. KS Afflictions loads vendor locale + tracking, suppresses independent /did/UI, provides a tiny tracker display compatibility shim and KS-owned bars for current target, focus and visible nameplates. Independent saved data `KSAfflictionsTrackerDB` prevents collisions with standalone DoesItDie; UI preferences live under `KoolSupportDB.modules.ks_afflictions`.

**Security/governance:** no automatic actions or rotation decisions; no Lua arithmetic/branching on Forever secret health values. Secret values pass directly to `StatusBar:SetMinMaxValues` and `SetValue`. Lethal icon uses an upstream-described clipping/statusbar UI-only approach; must be proven in client. Nameplate enumeration uses only visible unit tokens. DoT damage is estimated, not a guarantee. Disabled modules hide their rendering but already-loaded code persists until UI reload. Release requires real gameplay and CurseForge review.

**UI and testing:** Added shared `BarTheme.lua` for color/texture consistency and a KS Afflictions settings page. `scripts/check.py --package` includes new module and tests, plus separate optional `KSAfflictions_Plugin_0.9.0-dev.zip`. Browser HTML at `preview/KS_Afflictions_Browser_Preview.html` if committed, otherwise attached development artifact. Browser simulation uses mock encounters, not actual WoW Lua and is explicitly labeled. No screenshot of the simulator is presented as an in-game screenshot.

**Pending live-client smoke tests:** verify tracker startup `ADDON_LOADED`, spellcast and actual periodic damage correlation, status bar rendering of secret health, focus target, nameplates, module enable/disable, SavedVariables persistence, suspected-lethal indicator geometry, multilingual spell names and performance. Check target/focus frame anchoring and frame replacements. Disable the optional module instead of disrupting macro features if a display fails. Verify upstream MIT notices remain bundled.

**Next PRs:** refine target-nameplate styling and data validity after actual WoW footage; migrate common bar options to a true shared component across KS Stealth; make browser and native visuals closer; add modular JSON profiles separately. Do not advertise production parity until actual proof exists.


## Confirmed mainline follow-up — PR #5 and shared bars

- PR #5 **merged** on 2026-11-03 as squash commit `9eff27c8f31b8d02f4879160ddfd1da89bf6437c`. GitHub Actions passed, including Lua syntax, offline mocked Afflictions and legacy tests, package validation, license checks, and upload artifact. Additional local cold-start mock loaded all vendored Locale/Tracker/Bridge Lua, handled `ADDON_LOADED`, initialized KSAfflictionsTrackerDB and returned a valid empty DoT snapshot.
- The bundled optional KSAfflictions module is in **main**, and browser demo at `preview/KS_Afflictions_Browser_Preview.html` (simulated data, not client footage). It is still NOT a public release or verified in-game. Retain original DoesItDie MIT copyright (Joe Greive).
- This follow-up PR changes KS Stealth to use shared `KoolSupport.BarTheme:StyleBar(bar,"bleed")` for resource HUD segments, with an isolated-test compatibility fallback. Test now asserts all ten mock combo segments use shared style. All previous secure-value and toggle rules remain unchanged.
- Next principal engineer: verify current main/PR CI and new SHA, then smoke test KSAfflictions and KSStealth **together** in the real Forever client after launch: target, focus, several visible nameplates, resources under combat secrets, placements and persistence; observe CPU use. No automatic combat choices or health comparisons.

## New UI styling checkpoint — Modern KS default (PR pending, 2026-11-03)

**Product decision:** Make Modern KS the default visual appearance for KS Afflictions. Include Classic WoW and Minimal alternatives. Give players optional DIES text / Skull / Both / Off estimated-lethal indicators, a Purple / Gold / Red / Spell School DoT palette, actual spell icons when the client exposes textures, and compact size, frame and alert visibility settings. Do not alter Joe Greive's MIT tracking logic.

**Implementation:** `addons/KSAfflictions/Afflictions.lua` validates enum settings with new defaults (`style=modern`, `dotColor=purple`, `lethalMode=dies`). It preserves existing `KoolSupportDB.modules.ks_afflictions` keys. `Renderer.lua` owns custom KS style chrome, individual icon textures and `FontString` DIES text anchored to a clipping-statusbar boundary; the actual lethal state is determined by UI geometry, never by a Lua health comparison. Lethal visibility is independently toggleable for target, focus and visible nameplates. If the client cannot clip children, hide the indicator. No automatic casts/rotation decisions. `UI.lua` uses native WoW buttons with no nested scrolling.

**Browser simulator:** `preview/KS_Afflictions_Browser_Preview.html` supports the same style/color/indicator options using *simulated numeric health* and example DoTs. Browser comparisons are demo-only and **must not be copied into live addon Lua**; test the game client before claiming secret-value compatibility.

**Verification:** Added mocked Lua cases for style/default/enum validation, per-frame lethal visibility, mode toggles, and existing opaque health passthrough; confirm GitHub Actions result and exact PR merge commit before writing that tests pass. Browser JS syntax checked in V8 locally; actual browser interaction/screenshot should still be tested before a public preview release.

**Risk and release gate:** Live in-game confirmation remains mandatory for clipped DIES text, icon textures, nameplate layout and CPU usage. The 0.9.0-dev modular code still is not the publicly approved replacement for v0.6.4. No CurseForge upload changed. Compare interface against live screenshots after launch. The user's saved visual preferences should never be overwritten by defaults.

## 0.10.0-rc.1 checkpoint — class-aware recommended KS Macros / CurseForge beta candidate

**Decision:** The standard bundled KS Macros now ships practical class recommendations to add out-of-box value, without including session-only focus presets. Five macros per class are defined for the nine official Forever classes (45 total). `ClassPresets.lua` is class-scoped and only offers recommendations to the player's detected class; templates are optional, never automatically installed.

**Files/architecture:** `addons/KSMacros/ClassPresets.lua` provides curated templates, class icon atlas fallback, learned-spell requirement gating, and game-spell texture lookup. `Suite.lua` adds Recommended / General / Custom / All filters, icon display, requirement status (Ready / Locked / Verify), class-derived titles, review preview and explicit batch installation. `Engine.lua` accepts an optional native macro icon for `CreateMacro` and `EditMacro` while preserving question-mark fallback. Core, all five manifests and packaging have version `0.10.0-rc.1`. The standard CurseForge ZIP must contain **KoolSupport/** and **KSMacros/** only; separate optional ZIPs remain available. No new automatic combat logic; class-specific templates deliberately contain no @focus, with Support Sessions retaining that responsibility.

**Data preservation:** No changes to existing SavedVariables schema, draft ownership or migration. Existing unrelated/manually edited macros are still protected, batches preflight slots and names. When the spellbook API provides data, unlearned class recommendations cannot be selected. If unavailable, availability is explicitly unverified; the user may inspect and manually select an unverified macro. Never claim talent/level requirements are met.

**Documentation:** Software-only `docs/CURSEFORGE_DESCRIPTION.md`; `docs/RELEASE_NOTES_0.10.0-rc.1.md`; `docs/PUBLISHING.md` give exact CurseForge uploading and GitHub prerelease guidance. Previous CurseForge v0.6.4 review candidate remains untouched. Do not claim we uploaded, published or passed moderation. The RC is **Beta** until live Forever client tests verify interface number, all nine classes, spell icons, macro creation and optional module displays.

**Tests / handoff:** New `tests/test_class_recommendations.lua` validates all 45 entries, unique safe names, body limits, no @focus, spell requirements and icon fallbacks. Existing macro, spellbook, support, stealth and Afflictions tests must stay green. Inspect the actual PR/CI/merge results before citing them; `scripts/check.py --package` outputs `KoolSupport_CurseForge_Standard_0.10.0-rc.1.zip` for submission. At startup, verify current main and applicable build; do not assume a past PR remains latest.

**Next steps:** Obtain launch-client screenshots and run a class-by-class sampling smoke test; fix any API/spell mismatches without weakening macro governance; verify old v0.6.4 migration, source/test parity and module loading; then label the next stable release only after independent in-game confirmation.


## 2026-11-03: tag-only CurseForge packaging configuration

The project owner connected the public GitHub repo to CurseForge and saw automatic packaging options. We have a monorepo under addons/ containing Base, Macros and optional plugins; shipping that raw is unsafe and would not install with expected sibling directory layout.

A root .pkgmeta maps KoolSupport/addons/KoolSupport to KoolSupport and KoolSupport/addons/KSMacros to KSMacros. It excludes SupportSessions, Stealth, Afflictions, tests, docs, scripts, legacy, previews and GitHub workflows. Standard package remains Base + Macros only. New scripts/check_curseforge_packaging.py validates the intended layout. PR CI includes a BigWigsMods/packager@v2 dry-run with -d, then inspects the actual ZIP for unexpected files. This changes no Lua or SavedVariables.

Release governance: recommend 'tagged commits only' in CurseForge, not 'Package all commits'. Do not automatically tag merges; live Forever validation still blocks stable publication. Beta tags must contain literal beta (for example v0.10.0-rc.1-beta), because rc alone may not classify as Beta. Secrets stay outside source. Check CI and merge status in the latest main before claiming any automatic packaging works. The CurseForge project remains unlisted until the owner changes General settings.

See docs/PUBLISHING.md for the end-to-end instructions. No CurseForge upload or webhook creation is made in this sprint.

## One-click tag publishing workflow — 2026-11-03

Added `.github/workflows/publish-beta.yml`: manual workflow_dispatch, only on main, with an explicit true/false publishing confirmation; tests and dry-run package validation must pass before it uses the job-scoped GitHub token to create an immutable versioned `vVERSION-beta` tag. It refuses duplicate tags, a moved main branch, and non-RC versions. Tag is intended to trigger CurseForge's **external GitHub push webhook**, not a secondary GitHub Actions workflow.

Full pipeline: developer PR + updated handoff → CI green → merge → user configures CurseForge tagged-commits mode and GitHub webhook (secret CurseForge API token in the webhook Payload URL, NEVER in the repo) → user manually runs Publish Beta action → external CurseForge packaging → user checks file/moderation status. The GitHub connector cannot inspect or change admin webhook settings, and no CurseForge connector is installed, so external activation remains a user UI step.

Never create tags automatically on merges, and do not claim that CurseForge has published the addon merely because a tag exists. GitHub release tags may be immutable after external delivery. Beta status does not replace live client validation.

## KS Stealth Talent Impacts — Sprint 1 (2026-11-03)

**Requested and implemented on feature branch** `feature/ks-stealth-talent-impact-sprint1` (verify PR/CI and merge state). This is a **read-only catalog**, not a damage/crit calculator nor Blizzard talent-tooltip hook. The existing Nameplate combo point HUD is unchanged.

**Files:** `addons/KSStealth/TalentImpactData.lua` contains curated DRUID and ROGUE mapping tables with explicit ability lists and non-live effect descriptions. `TalentImpactUI.lua` renders a second KS Stealth page, opt-in via `KoolSupportDB.modules.ks_stealth.talentImpactOverlay` default OFF, with hover preview, click-to-select and spell texture lookup / safe icon fallback. `Stealth.lua` adds the persisted setting and out-of-combat toggling; `Module.lua` adds an optional-module-gated `stealth_talents` page. TOC loads catalog/UI before Module registration. Standard CurseForge Base+Macros package is unchanged: optional KS Stealth remains a separate ZIP.

**Catalog (build-sensitive):** Druid Ferocity (including Primal Bite), Shredding Attacks (Shred and Lacerate), Savage Fury (Claw/Rake/Shred/Maul/Swipe). Rogue uses **Nov 2 Forever** new names Efficient Strikes (Sinister Strike/Hemorrhage) and Coup de Grace (Eviscerate/Death Mark), plus Puncturing Wounds (Backstab/Mutilate) and Flawless Execution (Eviscerate). These entries were curated from talentsforever.com recent talent notes, not verified in a running client. Preserve source references in engineering review: https://talentsforever.com/druid/talents, https://talentsforever.com/rogue/talents/efficient-strikes, https://talentsforever.com/rogue/talents/coup-de-grace.

**Test:** `tests/test_talent_impact.lua` mocks the native UI and verifies opt-in default/persistence, class separation, current name mappings, hover display, missing spell textures, module-page gate and combat-toggling block. Run existing `scripts/check.py --package` plus CI; do not claim live validation until tested. It must never call protected combat values; no macros or SavedVariables keys are erased.

**Next:** player tests optional plugin installed with Base in Forever, `/kool` → Talent Impacts, ON → hover/click, verify UI layout and spell icons (Druid and Rogue), check toggle persistence after reload and no taint/errors in combat. Sprint 2: trained talent rank + highest learned spell-rank resolution, explicit calculations with damage subtype and crit-multiplier validation, optional read-only spellbook annotations. Native Blizzard talent-frame hover integration should be separately gated by runtime API verification. Avoid implementing Classic-era skills renamed/removed in latest Forever updates.

**Release note:** An independent v0.10.0-rc.1-beta GitHub tag and CurseForge **standard Base+Macros** publication exists, with external approval reported by owner. This PR does not touch that immutable tag, create a new release, or publish the optional plugin.


## Principal engineer checkpoint — 2026-11-03: ONE CurseForge suite / 0.10.x until Forever launch

**Product owner decision:** The user does **not** want separate CurseForge pages/downloads for the modules. ONE `KoolSupport` project (CurseForge project ID 1780256) must include the five sibling WoW AddOns directories in the **same installable ZIP**: `KoolSupport`, `KSMacros`, `KSSupportSessions`, `KSStealth`, `KSAfflictions`. The WoW folder-level modular architecture stays intact; the in-game Module Manager continues to enable/disable optional features, and the `KSStealth` Talent Impacts panel stays default-OFF. Treat the previous "separate optional addon downloads" wording above as **historical and superseded** by this decision. No separate CurseForge addon projects.

**Version governance:** The previously approved `v0.10.0-rc.1-beta` remains immutable and contains Base+Macros. Next candidate moves to `0.10.1-rc.1` (five modules). Remain on **0.10.x** throughout Forever launch testing **the evening of Nov 4, 2026** and any fixes; no stable declaration without live-game results. The existing manual publish action will derive `v0.10.1-rc.1-beta` from `scripts/check.py` once the owner expressly initiates it after testing. **Merging this PR must not create a new tag or CurseForge file.** The existing GitHub -> CurseForge push webhook remains tag-only, and a successful prior Beta delivery was reported.

**Packaging/code:** .pkgmeta move-folders entries for all five add-ons; ignores only development docs/tests/scripts/preview/legacy/GitHub/README. Keep Joe Greive's MIT `addons/KSAfflictions/Vendor/LICENSE` and `Vendor/NOTICE.md` inside the ZIP. `scripts/check_curseforge_packaging.py` validates exact five sibling roots, .toc, license, and source file lists against a *real* BigWigs dry-run ZIP. `scripts/check.py --package` creates + checks the same unified standard ZIP. A Base+Macros ZIP and per-plugin ZIPs can remain for development isolation only; don't advertise these as separate CurseForge install pages. All five .toc versions, Base KS.VERSION and check.py VERSION synchronize to `0.10.1-rc.1`. Update the publishing guide, description, README, release notes and road map accordingly.

**Data and operational safety:** Do not modify player SavedVariables, macro ownership fingerprints, native user-edited macros, combat restrictions or protected secret-value handling. The modules remain independent internally and retain existing .toc dependency declarations. Historical archival source and prior CurseForge tag are untouched. Beware that a "suite" install may load modules if the player's existing enablement settings permit, so test every module before new public file. The new Druid/Rogue Talent Impacts page is a read-only catalog and not live spellbook numbers or talent hover injection.

**Current engineering PR:** `feature/0101-unified-curseforge-bundle`; verify PR CI, merge and main SHA after work. **Must see** green offline Lua syntax/runtime tests *and* the real CurseForge packaging dry-run on PR and main. Do not claim it was merged or published until confirmed.

**Next player runbook Nov 4 evening:** (1) back up game `Interface/AddOns` and `WTF` and verify live Forever Interface marker instead of assuming 16001; (2) install the *unified development standard ZIP*, confirm five sibling .toc load order and module toggles; (3) check Macro Suite recommended spellbook icons/learned status, user-approved macro create/update/ownership rejection; (4) test Support Sessions and actual focus macros; (5) test Stealth combo points under real combat secret restrictions on multiple visible nameplates and Druid/Rogue Talent Impacts hover; (6) check Afflictions DoT estimates, target/focus/nameplate, visual styles, clipped lethal indicator and MIT vendor tracking; (7) reload, verify preserved settings, no Lua errors/taint, and rollback. Fix any issues as 0.10.x RCs. Only tag/publish Beta after owner explicitly approves; stable needs actual validated behavior. 


## 2026-11-03 — Talent Impacts Sprints 2 + 3, engineering checkpoint

**Task:** User requested both remaining Talent Impacts sprints implemented now, but live Forever rollout/testing still scheduled for November 4 evening. Do not extend the implementation into a new release tag or CurseForge upload without specific user approval. Branch `feature/stealth-talent-impacts-sprint2-3` (check resulting PR CI/main merge rather than assuming it).

**Architecture:** `KSStealth/TalentResolver.lua` reads committed active modern Forever `C_ClassTalents.GetActiveConfigID` / `C_Traits` config, tree/node/entry/definition names and ranks **out of combat**, with pending-staged-tree rejection, bounds, unsupported API fallbacks and secret-number checks. `C_SpellBook` provides highest learned named spell ranks. `C_Spell.GetSpellPowerCost` gives current cost only when available, never secret; `current + documented discount` is explicitly labeled **approximate**, not definite original cost. Percent damage uses a **normalized 100** example rather than fabricated live damage. Crit example optionally uses 200% of normalized baseline; crit chance is in percentage points. No armor/AP/buff/proc/rotation assertions.

**Features:** Expanded to six Druid talents (Ferocity, Feral Instinct, Shredding Attacks, Savage Fury, Natural Instinct, Rend and Tear) and ten Rogue talents (Efficient Strikes, Coup de Grace, Puncturing Wounds, Flawless Execution [10 Energy per latest reference], Aggression [Nov 2 rework], Improved Ambush, Dirty Tricks, Dirty Deeds, Elusiveness, Improved Slice and Dice). All have accurate affected-ability lists; only vetted, directly attributable modifiers have formula data. The KS Talent Impacts view pages talents, shows verified trained ranks/learned spell ranks, hover/click, and opt-in crit and annotation switches. `TalentTooltip.lua` feature-detects modern TooltipDataProcessor spell post-calls and appends read-only KS talent lines outside combat; a conditional `[KS talents]` marker is shown by KSMacros' own spellbook rows. Cache invalidated on guarded trait/spell events, all nameplate HUD behavior remains untouched.

**Status:** Read-only; no native tooltip replacement or combat input. Requires `tests/test_talent_resolver.lua`, `tests/test_talent_impact.lua` and all legacy tests + five-folder CurseForge packaging checks to pass before merge. Update code/data if failed; do not claim real Forever verification. `0.10.1-rc.1-beta` has already been tagged by the owner (successful GitHub run 41723314712). This feature is reserved for `0.10.2-rc.1` on main after CI; no tag or upload without explicit authorization. Retain single CurseForge project (ID 1780256) bundling five AddOns folders.

**Client gates Nov 4:** Confirm 16001 Interface, C_Traits active config + rank read and native spell names, real highest learned spell rank, mutable talent change refresh, spell-cost API under stance changes, normalized-vs-real labels, WoW TooltipDataProcessor callback and no taint/duplicate text, missing API graceful behavior and post-/reload toggles; then also perform previous suite-wide macros, support sessions, resource/secret and Afflictions smoke test. Account for historical Forever beta SavedVariables persistence bug reported in September 2026: do not guarantee cold-start setting persistence until checked against current live build. See `docs/ROADMAP.md` and `docs/ARCHITECTURE.md`.

References reviewed: https://github.com/Thunderz96/forever-addon-kit ; https://warcraft.wiki.gg/wiki/API_C_ClassTalents.GetActiveConfigID ; https://warcraft.wiki.gg/wiki/API_C_Traits.GetTreeNodes ; https://warcraft.wiki.gg/wiki/API_C_Traits.GetNodeInfo ; https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellPowerCost ; https://talentsforever.com/druid/talents ; https://talentsforever.com/rogue/talents/efficient-strikes ; https://talentsforever.com/rogue/talents/coup-de-grace ; https://talentsforever.com/rogue/talents/aggression .


## Pre-launch engineering Sprint 4 — Launch Checks (Nov 3, 2026)

The next priority after Talent Impacts Sprints 2/3 is to make Nov 4 in-client validation easier and observable. Branch `feature/launch-readiness-checks-0102` (verify PR/CI/merge). Added `addons/KoolSupport/Diagnostics.lua` to Base manifest, and a `/kool` → **Launch Checks** page via Base UI. It reports the detected client Interface number vs assumed `16001`, each of five bundle folders' loaded + registered + in-game-enabled statuses, and feature-detected spellbook, talent, native tooltip, visible nameplate and combo-point API availability. It does NOT call GetComboPoints or sample health, run combat, inspect spells or macros, or assert any feature is verified in game.

The page is a **read-only launch triage aid**, not a greenlight or automated smoke test: API presence alone proves nothing about runtime behavior, addon event correctness, UI secret values, macro safety or persistence. "OFF" is valid for optional modules, not a package defect. Its "REVIEW" on Interface mismatch does not auto-disable any module. A Re-run button rebuilds an ephemeral report, not persistent logs. Home text now correctly states all FIVE modules are included in a single CurseForge install. New `tests/test_launch_checks.lua` covers the statuses, failed/absent API alternatives, non-mutation of existing unknown settings, combat-resources-not-read and UI rendering. No change to version `0.10.2-rc.1`, no new CurseForge tag. If other tool or client API differs, use fresh client screenshot in Nov 4 tests to adapt conservatively. Developer must inspect CI and actual PR merge status before claiming success.


## Pre-launch Sprint 5 — 0.10.2 Macro migration and native API hardening (Nov 3, 2026)

User asked to keep engineering sprints moving before the Nov 4 Forever live client. Sprint 5 is focused on **preventing destructive macro writes** with real-ish legacy SavedVariables and native macro error mocks. Branch `feature/legacy-macro-ownership-hardening-0102`; confirm CI and merge outcome before claiming completion.

`addons/KSMacros/Engine.lua` import now grants legacy ownership only if the old `owned[name]` was precisely boolean true **and** the exact legacy-generated name/body passes existing macro validation. No stringy/truthy user value can claim a macro. The old root tables remain untouched. If old `customOrder` exists but is malformed, migration is left retryable instead of throwing or deleting/replacing the input; the valid legacy ownership portion may still copy conservatively. All migrated fingerprints still require **byte-for-byte** `GetMacroBody` equality before any native edit. No new macro is installed just because name lookup threw/returned garbage.

Native `GetMacroIndexByName`, `GetMacroBody` and `GetNumMacros` are handled as untrusted client APIs: error/malformed data -> a clear refusal, not a guessed empty macro slot or overwrite. `CreateMacro` and `EditMacro` are protected with `pcall`, and failed writes do not update the stored ownership fingerprint. Multi-install preflight rejects *all* ambiguous lookups, edited/unowned collisions, invalid templates, duplicate names and invalid/full macro slots **before** first write. Native creation can still fail partway through a batch (documented limitation); do not imply transactions on client API operations.

New `tests/test_macro_migration_hardening.lua` covers failed native calls, mutated old-owned macro bodies, duplicate legacy drafts, malformed legacy order/flags, invalid fingerprints, user keys preservation, preflight atomicity and combat refusal. Existing macro/test suite and full five-folder CurseForge dry-run must remain green. Source remains `0.10.2-rc.1` with *no new GitHub Beta tag* or public upload. The old 0.10.0/0.10.1 tags remain untouched. Live Nov 4 validation with backed-up player SavedVariables is still required.


## Pre-launch Sprint 6 — unified TOC startup regression (Nov 3, 2026)

Full single-project suite integration is more than five independently passing component tests. Branch `feature/unified-suite-coldstart-smoke-0102` adds `tests/test_unified_boot.lua`, a mocked **cold-load of every .toc in actual five-folder dependency/load order**: KoolSupport Base, KS Macros, KS Support Sessions, KS Stealth and KS Afflictions, including the shipped Joe Greive DoesItDie locales/tracker/bridge in one shared namespace. This checks module registrations, all ten feature pages, optional module UI gating, Support Sessions' Macros dependency, no macro creation during boot, and no unintended mutation of unknown SavedVariables fields or Afflictions vendor store. Requires the existing Lua suite and upstream CurseForge five-root ZIP dry-run to pass.

This is still **offline mocked Lua**, not proof that Forever accepts the live Interface number, API behavior, talent APIs, tooltip hooks, vendor DoT ticks, combat secret-value widgets or SaveVariables persistence across a real client relaunch. The user must test in actual game on Nov 4, after backing up WTF and AddOns. No new tag and remain on `0.10.2-rc.1`; prior published tags remain immutable.


## November 4, 2026 — CurseForge 0.10.2 approval and description refresh

- **Owner reports** CurseForge approved `v0.10.2-rc.1-beta` for distribution. GitHub run `41826003702` confirmed success and tag creation; previous failed run `41818111040` failed on a GitHub-side Internal Server Error while pushing the tag. Do not rerun or rewrite that immutable tag.
- The one-package, five-sibling-folder release, read-only Launch Checks, Talent Impacts and safer native macro migration remain unchanged. No Lua/gameplay, SavedVariables or packaging behavior was changed in this documentation-only PR.
- The CurseForge project description has been rewritten for players in `docs/CURSEFORGE_DESCRIPTION.md`: five included modules, quick start, class-aware Macros, opt-in Druid/Rogue Talent Impacts, limitations, source license and troubleshooting. The public CurseForge listing must still be updated manually by the project owner; GitHub docs do not synchronize its description.
- **Critical gate remains open:** WoW Forever launch client on November 4 at 6 PM ET has not yet validated spellbook, trait APIs, combat secrets, nameplates, Afflictions, native UI or per-character persistence. Approval/moderation is not proof of runtime behavior. Next sprint is in-game smoke tests and focused fixes using a NEW 0.10.x version, not retagging 0.10.2.


## November 5, 2026 — 0.10.3-rc.1 draggable KS Afflictions target/focus panels

- **Player observation:** A Forever screenshot shows a large `Target DoTs` HUD overlapping the play area. Approved and tagged `v0.10.2-rc.1-beta` remains frozen. The optional Afflictions module previously exposed only nameplate vertical offsets, not movable Target/Focus frames.
- **Implementation on feature branch:** target and focus unit HUDs get separate left-draggable 21px title grips, only outside combat, with independent per-character `KoolSupportDB.modules.ks_afflictions.hudPositions.{target,focus}` offsets anchored relative to UIParent. Existing defaults stay attached under Blizzard target/focus frames until moved. Adds `Reset Target` and `Reset Focus` actions. Does not add dragging to nameplate HUDs, change damage tracking, use secret health in arithmetic, or touch any existing player macros/legacy keys.
- **Version isolation:** bump all five manifests, Core and check.py to `0.10.3-rc.1`; no tag or CurseForge action. Preserve current 0.10.2 public Beta. No automatic promotion.
- **Offline acceptance:** extend `tests/test_afflictions.lua` for default anchor, drag/save, focus independence, refresh/recreation, reset, combat block, malformed position fallback and nameplate exclusion. Await CI success and mandatory Forever client verification of GetCenter/UIParent coordinate conversion, screen clamping, scale 0.65–1.65, /reload persistence, and no click interference.
- **Next:** smoke test 0.10.3 development candidate in Forever; if coordinate/mouse behavior differs, repair in a new PR before owner-authorized release.


## November 5, 2026 — 0.10.4-rc.1 simplified on-frame DoT overlays

- **Owner request and live visual reference:** Prefer compact purple estimated DoT coverage, tracked spell icons and `DIES` indicator on existing Target/Focus health bars, not a large, separate Target DoTs HUD. This is an **opt-in** preference; all 0.10.3 movable panels and saved per-character positions remain intact.
- The prior `v0.10.3-rc.1-beta` tag already exists and its manual Publish Beta GitHub workflow passed. **It is immutable; no new public tag without explicit owner approval.** Development version is now `0.10.4-rc.1` across five manifests, Core, checker and version-sensitive tests.
- **Implementation:** `KSAfflictions` gets `onFrame=false` in its existing per-character SavedVariables with a `Simplified / On-frame` UI toggle. Renderer resolves stock TargetFrame/FocusFrame health StatusBars via safe known classic and modern paths; creates noninteractive independent frames anchored to stock bars, displays a slim color-coded DoT estimate, up to three learned DoT spell icons, and the existing statusbar-based estimated lethal DIES/skull indicator. No reads/compares/formatting of secret health except direct passthrough to widget setters; original Blizzard health bars are never modified. If no compatible native bar is exposed, use the existing movable HUD. Nameplates retain their previous separate mode.
- **Regression scope:** off by default; toggle both modes; native bar discovery, fallback when Focus bar absent, original stock StatusBar integrity, nameplate independence, icons, DIES settings, out-of-combat settings restriction, and all prior saved HUD positions. Do not change DoesItDie engine or licenses, native macro ownership, addon folder layout or dependency model.
- **Live gates still open:** WoW Forever test of stock/modified unit frames, various UI scales, combat/target changes, native health text overlap, protected frame anchor restrictions, display appearance and estimated lethal indicator. No stable promotion on offline tests alone.


### 2026-11-05 — 0.10.4 Afflictions configuration layout hardening

- Screenshot of the user's live 0.10.3-rc.1 client confirms the on-frame toggle is unavailable there (0.10.4 is still an unpublished development candidate). Separately, the previous 0.10.4 UI placed the new toggle at y=-543 in the bottom crowded row, with explanatory content close to the 824x605 pane's edge.
- Documentation-only/source-only follow-up on 0.10.4 RC: KS Afflictions now presents **Simplified / On-frame** as a prominent top-level toggle (y=-109), always visible. Appearance and Colors vs Visibility and Position are two selectable sections; reset and nameplate adjustments remain on the latter. Status/footer remain inside the 605-high content pane.
- Added offline UI tests to check the toggle's placement, both tabs, click behavior, availability of reset controls, and every button's bounds relative to the native 824x605 settings pane. No tracker, health, secret/combat, saved-position, macro, or nameplate behavior changed.
- Current 0.10.4 RC remains **unpublished** and must not reuse the immutable 0.10.3 tag. Run GitHub PR+main CI; test the actual UI in Forever after installing the 0.10.4 development standard package. Client-only appearance/skin checks remain open; no public release without explicit approval.


## November 6, 2026 — 0.10.5-rc.1 Campfire Chat module

- **Current starting point:** Main `c1baf6eef070ac282c6da034fb4ab4e3c7ce99ca` (after 0.10.4 Afflictions layout PR #20). The prior `v0.10.4-rc.1-beta` Git tag exists; manual Publish Beta run `42144033289` succeeded. CurseForge approval is not confirmed by these checks. Do not rewrite any existing tag.
- **New feature:** independent sixth module `addons/KSCampfireChat` in the same standard ZIP and CurseForge listing. `Campfire Chat` becomes a module/page (requires only Base), with **Joke / Spooky / Ramble / Edgy Joke** player-click buttons and a visible player-buff status. `Campfire Nearby` is spell **1283391** (Forever); do not confuse this with `Camp Benefits` or `Welcoming Campfire`.
- **Design and restrictions:** 16 prewritten original short entries per category, shuffled bag avoiding repeats until exhausted, one direct hardware-click `SendChatMessage(text,'SAY')` per press only when the buff is positively detected via guarded modern/legacy aura APIs. An 8-second local cooldown; no queued multi-line messages, triggers, chat-on-load, slash automation, other chat channels or network calls. Outdoor SAY requires player hardware event; no bypass. Events may refresh availability only. Missing/unreadable aura, chat API or disabled module fails closed. No SavedVariables changes and no player macro operations.
- **Packaging/version:** `0.10.5-rc.1` candidate across six manifests, Core, scripts/check.py and all version-dependent tests; update `.pkgmeta`, real-packager validator, cold boot, diagnostics and docs. Prior MIT-licensed vendor remains fully preserved.
- **Required verification:** green PR+main Lua tests and real six-folder packager dry run; in-client confirm Campfire Nearby spell/aura recognition, button ON/OFF, exactly one nearby SAY per click, rate limit, permissions and unrelated addon regression before any separately owner-approved Beta tag. Browser-only preview is not game proof.
