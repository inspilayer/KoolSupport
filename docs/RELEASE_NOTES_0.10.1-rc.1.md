# KoolSupport 0.10.1-rc.1 — Unified Suite Candidate

**Release type:** development release candidate, intended for Beta after the November 4 Forever in-game smoke tests. No tag or CurseForge upload is created by this change. Existing approved `v0.10.0-rc.1-beta` remains immutable.

## One project, one download

The new **KoolSupport** CurseForge package includes five sibling WoW AddOns folders together:

- `KoolSupport/` — Base framework, main UI and module manager.
- `KSMacros/` — recommended class macros, Full Spellbook and Custom Builder.
- `KSSupportSessions/` — supportee/focus healing and follow/utility macro presets.
- `KSStealth/` — Rogue/Feral nameplate combo-point HUD and optional Druid/Rogue Talent Impacts page.
- `KSAfflictions/` — target/focus/visible-nameplate DoT estimates and customizable visual settings.

The modules retain their WoW `.toc` dependencies and enable/disable controls. This **does not require separate CurseForge pages**. No new macro-writing logic is introduced.

KS Afflictions includes modified MIT-licensed DoesItDie tracking by Joe Greive; upstream `Vendor/LICENSE` and `Vendor/NOTICE.md` are included in the bundled package.

## Safety and validation

- Original standalone v0.6.4 migration and hand-edited native macros remain protected.
- The already-approved standard Base+Macros beta is untouched.
- CI tests Lua syntax, mocked behavior, manifest consistency, all five addon ZIP roots and the real CurseForge packager dry-run.
- **Still required before publishing this candidate:** verify actual Forever client Interface number, module loading/dependencies, Druid/Rogue talent hover UI, nameplate combat-secret behavior, DoT estimates/indicators, Macro Suite installation and SavedVariables persistence.
- During testing, back up `Interface/AddOns` and `WTF` first. Disable any failing optional module; do not weaken combat restrictions.

### Version policy

Remain on **0.10.x** for launch iteration. This is `0.10.1-rc.1` in source. If player-tested and approved, a manually initiated GitHub Beta action will create `v0.10.1-rc.1-beta` and trigger the single existing CurseForge project. Do not promote a stable release until genuine client validation and any required fixes.
