# KoolSupport 0.10.8-rc.1 — One install folder

**Unpublished development candidate, not approved for CurseForge yet.** Existing `v0.10.6-rc.1-beta` and older release tags remain unchanged.

## What's changed
KoolSupport installs as **one folder**:
```text
Interface/AddOns/KoolSupport/
  KoolSupport.toc
  Core.lua
  UI.lua
  BarTheme.lua
  Diagnostics.lua
  Modules/
    KSMacros/
    KSSupportSessions/
    KSStealth/
    KSAfflictions/
    KSCampfireChat/
    KSThreat/
```
One World of Warcraft manifest loads each Lua source file in the correct dependency order. In-game `/kool` pages, character settings, the module manager, macro fingerprints, and enabled/disabled state still work independently. The source repo remains modular for unit tests. The official CurseForge packager and Python development ZIP builder are both tested to produce exactly **one** loadable root folder, including all bundled MIT vendor notices.

## Manual upgrade requirement
1. **Exit WoW**, and back up both `Interface/AddOns` and `WTF`.
2. Remove these **old root-level** addon directories only: `KSMacros`, `KSSupportSessions`, `KSStealth`, `KSAfflictions`, `KSCampfireChat`, `KSThreat`. Otherwise, the old code may duplicate registration and error at startup.
3. Extract the new ZIP to `Interface/AddOns`, replacing files in `KoolSupport`. Do not delete or reset WTF settings.
4. WoW retains the per-character `KoolSupportDB` because the physical addon name remains `KoolSupport`.
5. **Afflictions tracker database migration:** the original account-wide `KSAfflictionsTrackerDB` was saved in `WTF/Account/<account>/SavedVariables/KSAfflictions.lua`. The single-addon configuration stores it in `.../SavedVariables/KoolSupport.lua`. To carry over prior tracked history/settings, when WoW is closed, preserve a backup of the old file. If destination `KoolSupport.lua` does not exist, **copy** the old file into that name in the same SavedVariables folder. If destination exists, do not overwrite—manually merge only the tracker assignment after backup. The old file is left untouched automatically.

## Acceptance and rollback
- Offline: root TOC ordering, shared addon namespace for vendored DoesItDie tracker, six module registrations, diagnostics, secret-safe behavior, seven source groups, one-root Python ZIP, one-root real CurseForge packager ZIP, and MIT license/notice are tested by CI.
- Live-client gate: one installed KoolSupport entry, module pages, per-character state, /reload, Afflictions tracker initialization, KS Threat nameplates, macros unchanged; no duplicate module errors.
- Roll back by restoring backed-up AddOns **and** WTF; do not re-run an old tagged release or claim Beta stability without live verification.
