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
