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
