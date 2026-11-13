# KoolSupport 0.10.9-rc.1 — Centered DIES (development only)

**Unpublished development candidate.** No GitHub Beta tag or CurseForge upload is authorized by this change.

## What changed

- KS Afflictions now defaults to **Centered DIES**: no separate target/focus panels, DoT strips, icon rows, extra nameplate health bars, or popup widgets. Only a green-white outlined **DIES** FontString, centered over the original target/focus/enemy-nameplate health StatusBar, is eligible to appear.
- The new overlay is independent and mouse-transparent. It does not write to Blizzard health bar values, colors, positions, sizes, health text, cast bars, or secure actions. KS Threat and KS Stealth retain ownership of their own nameplate visuals.
- **Accuracy gate:** DoT damage must belong to the same verifiable unit key, have nonprovisional valid entries that have not expired, and be at least the enemy's **nonsecret** current health. When health is secret, missing, unsupported, or not positively attributable, **DIES is hidden**. The old wide clipped StatusBar is **not** used to manufacture a Boolean lethal signal. Its visual technique is not exact near a threshold.
- Updates are driven by health, target/focus, nameplate, combat, spell and aura events, with a limited 0.5-second expiry recheck **only while an indicator is displayed**, using the tracker’s existing housekeeping. No new heavyweight render polling.
- The settings page gives three obvious modes: **Centered DIES**, **On-frame Extras**, and **Movable Panels**. Former UI styling, spell icons, colors and saved panel positions are retained for advanced modes.
- One installable `KoolSupport/` root and the six nested source modules are unchanged. Vendored DoesItDie MIT code, notices, raw tracker store and macro protections remain untouched.

## Backward-compatible settings migration

`KoolSupportDB.modules.ks_afflictions.displayMode` is added. Existing `onFrame=true` selects On-frame Extras; discernible custom styles, icon choices or saved panel positions select Movable Panels. New installations and old default-equivalent profiles choose Centered DIES. Existing keys and unknown records are not deleted. Prior `onFrame=false` was automatically persisted by older releases even without user interaction, so an explicit OFF click is indistinguishable from that old default; the migration documents that ambiguity rather than pretending it can recover click history.

## Test gate / known limitation

Offline tests cover secret-value refusal, invalid/stale/provisional estimates, target/focus/plate attribution, damage/health transitions, no native bar modification, settings migration, independent KS Threat/Stealth frames, and existing legacy display modes. CI must pass the complete Lua suite, one-folder dev ZIP verifier and **real BigWigs packager dry run** before merge.

**Forever live-client validation is still required.** If Forever marks `UnitHealth(unit)` secret during combat, no DIES word appears for that unit; this is a deliberate safe limitation, not a UI positioning defect. No secure-handler bypass or secret numeric comparison has been introduced. Observe whether secure native frames allow the independent overlay to anchor, the font layers cleanly above KS Threat, and the vendor properly tracks real DoT ticks.

## Installation for testing

Completely exit WoW and back up `Interface/AddOns` and `WTF`. Install the single development `KoolSupport/` folder under `Interface/AddOns`. Remove the **six obsolete sibling addon directories** from older pre-0.10.8 installations to prevent duplicate loading. Keep the existing `KoolSupportDB` and carefully preserve the former separate `KSAfflictionsTrackerDB` by following the 0.10.8 migration instructions; never overwrite an existing `SavedVariables/KoolSupport.lua` with the older tracker file.

Test lethal Rip/bleeds on **target, focus, and two visible nameplates**, switching targets and healing/dispelling DoTs. Compare with On-frame Extras or Movable Panels to diagnose tracker accuracy; record client secret-health behavior and any Lua errors. Do not authorize Beta until the live result is satisfactory.
