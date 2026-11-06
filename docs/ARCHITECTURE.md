# KoolSupport modular architecture

Updated 2026-11-03 — current candidate **0.10.1-rc.1**. Already-approved 0.10.0 Beta remains immutable; live Forever verification is still required before a stable release.

## Physical dependency graph

```text
KoolSupport/                       required Base + UI shell
KSMacros/                          required, ships with Base (`## Dependencies: KoolSupport`)
KSSupportSessions/                 optional (`## Dependencies: KoolSupport, KSMacros`)
KSStealth/                         included, player-toggleable (`## Dependencies: KoolSupport`, `## OptionalDeps: KSMacros`)
KSAfflictions/                     included, player-toggleable (`## Dependencies: KoolSupport`)
```

All `.toc` directories are siblings within `Interface/AddOns`, never nested. CurseForge's single standard package includes **all five sibling addon folders together**. Their runtime enablement is still controlled through the Base Module Manager, and dependencies are enforced. Standalone developer ZIPs are for isolated smoke tests, not separate CurseForge projects. Loaded Lua does not unload without `/reload`.

## Ownership

- **Base**: Home, module registration (`API_VERSION=1`), dependency and toggle enforcement, shared shell and SavedVariables root. No spell actions or macro writes.
- **KS Macros**: generic Macro Suite templates/drafts, actual learned active spellbook enumeration, custom builder palette and native macro installer. Does not select a healer or supportee and does not contain class-specific healing presets.
- **KS Support Sessions**: optional class-aware focus/focustarget/follow/heal/utility presets, supportee name/recipient class selection, checks whether individual templates are selected, delegates every macro installation to `KSMacros:Install`. Presets derive from archived v0.6.4 Profiles source, not newly imagined abilities.
- **KS Stealth**: optional Rogue/Feral nameplate information display, sized/positioned from per-character settings, with a shell page. It does not need KS Macros to render. Future macro templates may integrate with Macros if present.
- **KS Macro Profiles**: planned; optional dependent on Macros. Versioned share/import/export by copy/paste JSON, not disk reads from Lua.

## Module and page API

`KoolSupport:RegisterModule({id,title,apiVersion=1,defaultEnabled,requires,onEnable,onDisable})`

`KoolSupport:RegisterPage({id,title,moduleId,build(parent,core)})`

`IsModuleEnabled`, `SetModuleEnabled`, `ShowPage`, `CanOpenPage`, `GetDatabase`, `IsInCombat` are Base-owned. The Base navigation discovers registered module pages, and disabling a module hides its pages. Base blocks disabling an enabled dependency while a dependent is active. Module toggles cannot change in combat.

## Per-character persistence and legacy compatibility

`KoolSupportDB` remains `## SavedVariablesPerCharacter` in Base. No old keys are removed. `KSMacros:Store()` performs a single idempotent migration to `KoolSupportDB.modules.ks_macros`:

- Reads `KoolSupportDB.customDrafts`, `customOrder` and copies recognized valid bodies into namespaced `drafts` and `draftOrder` only if destination names are empty.
- Copies previous `owned[name]` only if it has the matching last-written `generated[name]` body; new macro-update verification compares the current native macro body with the saved fingerprint.
- Keeps all legacy root tables intact and marks `legacyMigrationV1` after conversion.

`KSSupportSessions:Store()` copies only missing legacy `character`, `recipientClass`, `spec`; selection of support macros consults old per-profile enabled settings when no new explicit override exists. Neither plugin deletes old records.

No full live-client migration can be claimed until the SavedVariables format is actually tested in Forever. The preserved monolith baseline is `legacy/v0.6.4/` and is **not shipped**.

## Macro safety and governance

Only explicit player clicks outside combat create/edit a native macro. No automatic target-follow loops, secure-action bypasses, combo-point-based rotation decisions, remote control or cross-client input broadcasting. Macros are not executed by the addon. Validate 255-byte bodies, 16-byte conservative names, and put `#showtooltip` on line 1. Native names not owned by this addon, or edited by a player, must never be overwritten. Macros cannot bypass Blizzard's restricted commands or client level/talent gates.

## KS Stealth nameplate resource design

Use `C_NamePlate.GetNamePlates()` and `GetNamePlateForUnit()` with `nameplateN` unit tokens to discover **visible nameplates**. There is no supported API for discovering every enemy in a radius or off-screen. Each nameplate gets five `StatusBar`s, with fixed ranges `[0,1]` through `[4,5]`. Pass the result of `GetComboPoints("player", unit)` directly to each `StatusBar:SetValue(points)` without comparing, counting, formatting, indexing or testing the value in Lua. Filled portions are visible; at zero the bars show no fill. No Lua decision on which targets have points.

Events: `NAME_PLATE_UNIT_ADDED`, `NAME_PLATE_UNIT_REMOVED`, `UNIT_COMBO_POINTS`, `UNIT_POWER_UPDATE`, `UNIT_POWER_FREQUENT`, `PLAYER_TARGET_CHANGED`, `PLAYER_ENTERING_WORLD`, `UPDATE_SHAPESHIFT_FORM`. No combat automation or periodic range scanning. Secret-value handling and API access for **non-current** nameplates require live-client verification. If the engine hides those values, show only what can be displayed; do not substitute fabricated points. Do not claim reliable arbitrary-unit range detection.

## Packaging and release boundary

`scripts/check.py --package` validates all four manifests, Lua source, runtime tests, and creates:

- `KoolSupport_Base_Macros_0.8.0-dev.zip` — standard bundled download.
- `KSSupportSessions_Plugin_0.8.0-dev.zip` — optional child requiring both.
- `KSStealth_Plugin_0.8.0-dev.zip` — optional sibling requiring Base.
- `KoolSupport_All_Modules_Development_0.8.0-dev.zip` — test bundle only.

Version and interface `16001` are development values. Browser HTML previews are mockups. The old v0.6.4 CurseForge submission must not be modified or replaced until the user explicitly authorizes a tested upgrade. Offline tests aren't proof of Forever client compatibility. Maintain `docs/CHAT-TRANSITION.md` **in every substantive PR**.


## KS Afflictions: optional MIT-licensed DoT module (0.9.0-dev)

`KSAfflictions/` is an **independent optional sibling** that hard-depends only on KoolSupport Base. It bundles a *modified tracking-only* slice of [DoesItDie](https://github.com/swirllyman/DoesItDie) (Joe Greive, MIT) under `Vendor/`; license notice in `Vendor/LICENSE`, modifications in `Vendor/NOTICE.md`. No separate DoesItDie installation is needed.

- Vendor tracking reads casts, `UNIT_COMBAT` ticks and estimates future remaining DoT damage. It does not automatically cast a spell or claim mathematically certain lethal outcomes.
- Vendor Options, standalone nameplate/frame displays, textures, slash commands and experimental probes are **not bundled**. `TrackerBridge.lua` replaces display hooks and the module renders its own KS-styled bars.
- `KSAfflictionsTrackerDB` is the tracker-only SavedVariables store, deliberately distinct from `DoesItDieDB`; per-character UI preferences use `KoolSupportDB.modules.ks_afflictions`, without changing legacy keys.
- Optional target/focus/nameplate displays show health and the remaining DoT estimate side-by-side; nameplates are limited to *visible* unit tokens. The optional lethal icon uses only statusbar fill/clipping geometry. No comparing, formatting, subtracting or branching on secret health in Lua.
- `KoolSupport.BarTheme` is the shared statusbar palette. Modules may reuse it; KS Afflictions does not depend on KS Macros or KS Stealth.
- Independent module toggles hide the UI; Lua already loaded by WoW stays loaded until reload.
- Browser simulation is demonstrative only; demo health and damage are fabricated test values, and its lethal visualization is ordinary JavaScript rather than client-side secret-value UI machinery.

**Release gate:** live test DoT attribution (especially combo finishers), focus, multi-nameplate behavior, secret-value drawing and layered icon geometry. No CurseForge release of 0.9.0-dev is authorized.

## KS Afflictions visual styles — 0.9.0-dev development

- `style`: `modern` (new user default), `classic`, `minimal`. Style affects frame background, typography and compactness; not tracking data.
- `dotColor`: `purple` (default), `gold`, `red`, `school`. Settings are validated against a finite allowlist, not arbitrary Lua/eval.
- `lethalMode`: `dies` (default), `skull`, `both`, `off`. Individual `lethalTarget`, `lethalFocus`, `lethalNameplates` visibility controls. Legacy `lethal` remains as a master switch. New defaults only fill missing saved keys; no destructive migration.
- UI-only lethal indicator uses a `StatusBar` whose maximum comes directly from `UnitHealth(unit)` (may be a Forever secret), value comes from non-secret estimated DoT damage, and a `FontString`/skull anchored at the status-bar fill edge and clipped by a child frame. Do NOT compare, convert to string, branch or compute using `UnitHealth` in Lua.
- Spell textures use supported client API where available and safely hide unavailable icons. Browser demo's direct health comparisons are **simulation only**.
- Security, accuracy and client-release constraints from the previous sections remain in force.

## Built-in KS Macros: recommended class catalogs

The built-in generic module detects one of the nine Forever class tokens with `UnitClass("player")`. `ClassPresets.lua` defines five optional recommended quality-of-life templates per class; `Suite.lua` shows these under Recommended, followed by generic templates and saved drafts under separate filters. No `@focus` appears in class templates; the optional Support Sessions addon owns target-name setup and focus-based healer presets.

When `ScanSpellbook()` works, known active learned spells are mapped by name and required spells are checked before selecting a recommendation. When scanning fails, recommendations are labeled **Verify**, not falsely marked available. A spell icon comes from `C_Spell.GetSpellTexture(spellID)` or `GetSpellTexture(spellID)`, with class atlas fallback in the UI. Installed macros accept the resolved native icon ID or default to the secure game's question-mark icon with #showtooltip. User selection and native engine protections remain mandatory.

The previous approved `0.10.0-rc.1-beta` *did* bundle only Base and Macros. Starting with 0.10.1-rc.1, the new unified standard zip deliberately includes Base, Macros, Support Sessions, Stealth and Afflictions as five siblings in one CurseForge listing. Remain on the Beta/RC line until live Forever class/spell validation. Original KS Afflictions MIT notices remain distributed unchanged.


## KS Stealth Talent Impacts (Sprint 1, optional)

`TalentImpactData.lua` is a static class-scoped Druid/Rogue Forever talent-to-ability catalog. `TalentImpactUI.lua` registers a separate read-only Talent Impacts page via Module.lua, protected by the existing `ks_stealth` module gate. Native class tokens (UnitClass second return) determine the view; unsupported classes do not receive an active list. A new default-OFF `KoolSupportDB.modules.ks_stealth.talentImpactOverlay` setting is additive and never removes unknown keys. The toggle respects existing combat setting restrictions.

The page provides talent hover/click previews with spell textures when available. There is no API to scan learned talent ranks or spell ranks in this sprint, no Blizzard talent-frame hooks or spellbook mutations, and no numeric damage/crit calculation; effects are explanatory catalog text sourced from November 2026 Forever talent notes and subject to client verification. No combat secrets are passed through this UI. The 0.10.1 candidate's single CurseForge package contains this Talent Impacts UI as part of the bundled Stealth sibling folder; it remains opt-in and read-only.


## 0.10.1-rc.1 unified distribution contract (supersedes earlier packaging checkpoints)

The package-as `KoolSupport` CurseForge project **1780256** ships one ZIP with exactly `KoolSupport/`, `KSMacros/`, `KSSupportSessions/`, `KSStealth/` and `KSAfflictions/` at the root. The GitHub tag packager applies root `.pkgmeta` `move-folders` for all five directories. `scripts/check_curseforge_packaging.py` and the upstream packager dry-run assert manifests, namespaced folders, vendor licensing and no development files. `scripts/check.py --package` independently constructs and verifies the same unified folder topology.

Runtime modules keep `.toc` dependency declarations and optional in-game enable/disable controls; do not collapse source into one loader file or remove persistence. `KoolSupportDB` and `KSAfflictionsTrackerDB` schemas are preserved. New files are not added to the already published `v0.10.0-rc.1-beta` tag. The manually initiated next `v0.10.1-rc.1-beta` is contingent on player validation in Forever on November 4, 2026, and separate owner approval. No PR merge triggers a CurseForge submission.


## Talent Impacts Sprints 2/3 — read-only resolution and tooltip integration

`KSStealth/TalentResolver.lua` reads the **committed active** C_ClassTalents configuration and trait tree/node/entry/definition spell names (out of combat only) to resolve points. No Classic `GetTalentInfo` is used. If active config, committed state, node data, or mapped talent names are unavailable, the result is explicitly **unverified**; a missing talent name is never silently assigned a rank. Data is not written back to game systems or character SavedVariables. A bounded spellbook scan picks highest known spell ranks from native `C_SpellBook` slots without relying on old Classic globals.

`TalentImpactData.lua` now has explicit per-ability modifier data: `damage_pct`, `crit_chance`, `cost_flat`, `cost_pct` and `cooldown_flat`. `AbilityInsights` displays the effects only for **confirmed trained ranks**; it does not inspect combo points, target health, combat auras, target armor, attack power or combat events. A normalized 100-damage example may show 100→110 and optional **200% critical strike example** 200→220, **not an actual hit**. For cost reductions only, read the *current* cost from `C_Spell.GetSpellPowerCost(spellID)` if it returns a nonsecret number matching the requested resource, and display the calculated counterfactual `current + discount` as **approximate** because other effects may alter it. If missing, show only documented talent modifier.

`TalentTooltip.lua` installs an optional, feature-detected read-only `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell)`, guarded by Base module state, Talent Impacts opt-in, `talentAnnotate` preference (default OFF), available player snapshot and **out-of-combat** state. It never replaces Blizzard frames or alters ability logic. `KSMacros/Spellbook.lua` conditionally shows `[KS talents]` on learned rows when matching confirmed modifiers exist. Hook installation recovers at login if saved preference is ON; native hook remains installed for the session but its callback becomes inert when disabled. Talent/spell events invalidate its in-memory snapshot, guarded against unsupported Forever event names.

`TalentImpactUI.lua` has paged Druid/Rogue talents, hover/click preview, rank and learned-spell indicator, optional tooltips/crit switches and manual refresh. The catalog is intentionally restricted to Druid and Rogue, per product owner. All new `KoolSupportDB.modules.ks_stealth` preferences are additive and remain default-OFF; no macro or existing SavedVariables migration is changed. Live Forever tests, API probes and screenshots still gate release.


## Read-only launch diagnostics

`KoolSupport/Diagnostics.lua` is a Base-only capability detector, loaded before `UI.lua`. `CollectLaunchChecks()` creates an ephemeral table describing the known five-addon layout, registered/enabled module state, client Interface version versus `16001` development assumption, and entrypoint presence for spellbook, traits, tooltip, nameplates and combo points. No `GetComboPoints` call, combat-state inspection or cast/macro edits are permitted from this code. Native AddOns metadata access is guarded with availability checks; unsupported APIs display "UNVERIFIED", not healthy. `UI.lua` renders the results as an ordinary pageless `launch_checks` page in the Base app with a manual refresh control. All checks are informational, not live feature tests or a release gate bypass. Added `tests/test_launch_checks.lua`.


## Legacy migration and macro API hardening

Legacy `KoolSupportDB.owned[name]` may only become `modules.ks_macros.owned[name]` when exactly boolean `true` and the historical `generated[name]` body satisfies native safe length/name validation. Neither legacy root value is deleted. Native installation still checks exact last-written body fingerprints against current `GetMacroBody(index)`; a hand edit makes the macro **unowned for updates** until the player explicitly resolves it. Malformed legacy `customOrder` is left untouched and migration remains retryable.

Preflight wrappers for native `GetMacroIndexByName`, `GetMacroBody`, and `GetNumMacros` reject errors, nonnumeric indexes and unknown slot count. `CreateMacro`/`EditMacro` failures are trapped and do not advance the stored ownership hash. Duplicate names, conflicting edits, invalid macros and insufficient known slots all fail before batch writes start. The native WoW API cannot guarantee true transaction/rollback across a partly completed batch; a later API refusal reports the completed count. `tests/test_macro_migration_hardening.lua` provides mock regression cases without any real user macro data. No change to existing SavedVariables schema.


## 0.10.5 Campfire Chat module (Nov 6, 2026)

- Sixth sibling addon folder `KSCampfireChat/`, declared `## Dependencies: KoolSupport`. No requirement on Macros or Afflictions; module ID `ks_campfire_chat`, page `campfire_chat`.
- `Content.lua` is a self-contained catalog of 16 original, brief entries each for Joke, Spooky, Ramble and Edgy Joke. A shuffled draw bag avoids repeats until exhausted and avoids immediate repeats across bag resets. Edgy means playful tavern sarcasm, not hateful or obscene content.
- `CampfireChat.lua` only recognizes the real player aura `Campfire Nearby` (Forever spell 1283391), using guarded modern `C_UnitAuras` and classic `UnitBuff`/`UnitAura` fallbacks. Absent, unreadable or secret aura data **fails closed**. It sends at most one <=240-byte `SAY` message per **direct native button OnClick**, with an 8-second client-local cooldown. There is no OnUpdate timer for sending, no other chat channel, no party monitoring, no automatic macro or cross-client control, and no external requests.
- `UNIT_AURA` events are used only to refresh the visible buff indicator and buttons; events cannot send messages. `UI.lua` is another native page within the existing Base window. Buttons are inactive while the buff is not confirmed. Disabling the module in Modules hides its page and blocks sending. No SavedVariables migration is needed and the existing per-character data is untouched.
- Packaging: main CurseForge standard bundle now contains **six sibling addons** without a separate listing. Previous 0.10.4 tag and files remain immutable. A real Forever test is required because outdoor `/say` is hardware-event-restricted and client aura API paths can vary.
