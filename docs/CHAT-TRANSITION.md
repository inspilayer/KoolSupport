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
