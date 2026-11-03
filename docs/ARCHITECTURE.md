# KoolSupport modular architecture

Updated 2026-11-03 — current development checkpoint **0.8.0-dev**. This is not a released replacement for monolithic v0.6.4.

## Physical dependency graph

```text
KoolSupport/                       required Base + UI shell
KSMacros/                          required, ships with Base (`## Dependencies: KoolSupport`)
KSSupportSessions/                 optional (`## Dependencies: KoolSupport, KSMacros`)
KSStealth/                         optional (`## Dependencies: KoolSupport`, `## OptionalDeps: KSMacros`)
```

All `.toc` directories are siblings within `Interface/AddOns`, never nested. Package the standard Base download with `KoolSupport` and `KSMacros` together. Optional addons have separate ZIPs and are hidden/disabled in the Base module manager when not installed or switched off. Loaded Lua does not unload without `/reload`.

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

Do not bundle optional plugins into the standard CurseForge upload. The standard upload ZIP contains only Base and KS Macros siblings. New candidate `0.10.0-rc.1` is a Beta/RC until the live Forever client and class spell names are validated. Original KS Afflictions MIT notices remain distributed unchanged.


## KS Stealth Talent Impacts (Sprint 1, optional)

`TalentImpactData.lua` is a static class-scoped Druid/Rogue Forever talent-to-ability catalog. `TalentImpactUI.lua` registers a separate read-only Talent Impacts page via Module.lua, protected by the existing `ks_stealth` module gate. Native class tokens (UnitClass second return) determine the view; unsupported classes do not receive an active list. A new default-OFF `KoolSupportDB.modules.ks_stealth.talentImpactOverlay` setting is additive and never removes unknown keys. The toggle respects existing combat setting restrictions.

The page provides talent hover/click previews with spell textures when available. There is no API to scan learned talent ranks or spell ranks in this sprint, no Blizzard talent-frame hooks or spellbook mutations, and no numeric damage/crit calculation; effects are explanatory catalog text sourced from November 2026 Forever talent notes and subject to client verification. No combat secrets are passed through this UI. The KS Stealth plugin ZIP alone includes these files, while the standard Base+Macros CurseForge ZIP remains unaffected.
