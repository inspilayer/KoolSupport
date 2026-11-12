# KoolSupport 0.10.6-rc.1 — KS Threat

**Status: unpublished development candidate.** The v0.10.5-rc.1-beta tag and any approved CurseForge files remain immutable.

## New: lightweight tank threat coloring
- KS Threat is a separate optional module bundled inside the same KoolSupport installation, no third-party ThreatPlates-style framework required.
- Enable per character under /kool > Modules > KS Threat.
- Color scale: **RED (threat status 3, securely tanking)**, **PINK (2)**, **VIOLET (1)**, **PURPLE (0, low or none)**.
- Default: disabled; when enabled, show only hostile enemies that are in combat; purple for no threat can be hidden by preference.
- Uses Blizzard enemy nameplates with a small mouse-transparent color StatusBar laid over each native health bar. No replacement, resizing or recoloring of the actual Blizzard statusbar or cast bars. Other KoolSupport modules (including Afflictions/Stealth) stay independent.
- Event-driven only. No constant per-frame polling, huge library, aura scan, macro edits or automation.

## Forever client restrictions
- The game exposes four categorical threat statuses; exact numerical threat and percentage lead may be hidden and are never inferred.
- The addon checks for unreadable/secret threat and hostile/engagement values before using them. Unknown statuses and unsupported nameplates retain their native colors.
- Secret health passes directly into this addon's own StatusBar setters without being inspected or compared.

## Validation
Mocked Lua tests cover all threat colors, the non-hostile/inactive/unknown gates, protected secrets, native health bar integrity, stable overlay reuse, module defaults, combat-sensitive settings, and nameplate lifecycles. CI also tests cold boot, seven-folder CurseForge package and isolated dependency loading.

**Actual Forever client acceptance needed before a public tag:** test a Feral Druid tank in pulls with multiple enemies; confirm threat colors as enemies switch aggro, no interference with native health labels, casts, KS Stealth and KS Afflictions, disappearance/reappearance, and fallback on different nameplate skins.
