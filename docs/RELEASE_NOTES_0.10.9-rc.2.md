# KoolSupport 0.10.9-rc.2 — Afflictions advanced-alert safety (development only)

**Not a CurseForge Beta or stable release.** No existing tags changed.

## What the user saw

A real Forever screenshot showed green/purple **DoTs** strips on two nameplates and a floating green **DIES** to the right of the selected enemy's bar. This is the **previously saved On-frame Extras** mode, deliberately preserved by 0.10.9's migration. It is not the new text-only mode.

## Changes

- Retire the *old 18,000px clipped StatusBar* pseudo-detector from legacy panel and on-frame displays. It was a geometry approximation, not a reliable Boolean lethal check. Its DIES word could appear off to the side or flicker near a threshold.
- On-frame and legacy panel alerts now use the same strict `ConfirmedLethal(unit)` predicate as Centered DIES mode. Any secret/invalid health, untrusted unit attribution, stale or provisional DoT estimate results in **no DIES/skull**.
- On-frame Extras centers the approved word/skull inside the host native health bar overlay. Movable Panels/nameplate advanced HUDs center it on their own displayed health bars. No giant offscreen StatusBar or offbar label.
- KS Afflictions settings now show **Active: [display mode]** and explicitly explain that selecting **Centered DIES** turns off all extra DoTs strips/windows.
- Saved modes, DoT tracking, HUD coordinates, macro ownership, the single installed KoolSupport folder, KS Threat, KS Stealth, and Joe Greive's original MIT vendor files/notices remain unchanged.

## Verification and client gate

All Lua offline tests, source syntax, unified ZIP verification, actual BigWigs-compatible CurseForge packager dry run, and PR/main CI must be green. Manual live validation remains required: select Centered DIES in `/kool`, verify extra bars disappear, then compare each target/focus/nameplate against advanced modes for placement, health-secret behavior, and rapid changes.

**Important:** If Forever makes `UnitHealth` secret during combat, any exact conditional text remains hidden in **all** modes. No bypasses or fabricated positive outcomes. No new Beta tag without owner approval.
