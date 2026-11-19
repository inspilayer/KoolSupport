# KoolSupport 0.10.15-rc.2 — Development candidate (not public Beta)

## New in rc.2: movable KS Stealth combo HUD

- Still **one** KoolSupport AddOns directory and **seven** registered modules; no separate downloads.
- In **KS Stealth**, enable **HUD: ON**, click **Unlock / move HUD** and drag the gold **DRAG COMBO POINTS** handle. Click **Lock HUD position** when done.
- A five-gold-pip HUD shows combo points for the selected target on Druid/Rogue. While locked it hides when target is lost; while unlocked it stays visible with empty pips to make positioning easy.
- Independent of the existing pips above enemy nameplates; either display can be turned off without disabling the other.
- HUD scale, position, visibility and lock state persist per character. Includes **Reset position**. Changing settings/dragging in combat is blocked.
- World of Warcraft Forever restrictions: opaque/secret combo values are passed directly to native Blizzard StatusBars, with **no** Lua numeric comparisons or automatic gameplay decisions.

## Retained from 0.10.15-rc.1

KS Quest Checker: partial/fuzzy name search, numeric ID lookup, read-only actual character completion flag, optional separately installed QuestieDB full catalog, and recent quest IDs. Other six pre-existing modules, DIES, silver external tag threat, XP timer and all saved variables are unchanged.

## Release gates

Development ZIP only; no CurseForge tag or public upload. Before new Beta, verify Forever Rogue/Druid live target changes, combo gain/spend, lock/drag, reload persistence and HUD/nameplate independent toggles. Require green CI Lua tests and real single-root CurseForge packager dry run. Existing `v0.10.14-rc.1-beta` remains immutable.
