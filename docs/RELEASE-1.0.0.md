# KoolSupport 1.0.0 — Public Release Notes

KoolSupport is one installable World of Warcraft: Forever addon with nine independently configurable modules. Install **only** the `KoolSupport` folder from the verified ZIP under `_forever_/Interface/AddOns/` and type `/reload`. Open the dashboard with `/kool`.

## What's new

- **Unified user interface:** compact slate-and-gold navigation, clearer section buttons, consistent smaller typography, and module manager.
- **KS Macros and Support Sessions:** class-aware recommended macros, spellbook tools, safe user-triggered installation, and healer/support session setup.
- **KS Stealth:** automatic target-nameplate combo-point pips, a visual Pip Designer, personal Energy bars, custom energy breakpoints and rectangular segments, and talent-impact reference tools.
- **KS Afflictions:** configurable damage-over-time tracking and estimated lethal indicators built on the licensed DoesItDie tracking engine.
- **KS Threat:** opt-in threat and tag-ownership assistance.
- **Campfire Chat:** optional themed original chat lines with campfire buff gating.
- **KS Quest Checker:** read-only lookup of known and installed quest data and character completion flags.
- **Guilty Forever:** private notes, player tags and reminders.
- **Sleeping Bag Navigator:** optional draggable route assistance for the Cozy Sleeping Bag quest chain, including faction-specific starting steps, map pins, and manual overrides for hidden objectives.

## Privacy and player control

Everything runs locally in the game client. No automatic spell casts, player movement, macro overwriting, or automatic quest interactions. Saved per-character settings are retained from compatible earlier KoolSupport builds. Sleeping Bag Navigator and KS Threat are disabled by default.

## Important notes

- Target-nameplate rendering and the waypoint arrow depend on APIs exposed by the Forever client. Cross-zone destinations use text and map hints rather than a misleading straight-line arrow.
- Sleeping Bag coordinates are approximate; some quest objectives are on different elevations.
- Third-party Afflictions tracker license and modifications are retained in the ZIP.
- This document describes the intended **1.0.0** release artifact. Public status is not established until the owner confirms the nine-module live smoke test and the manual GitHub release workflow publishes and validates the resulting downloadable asset and CurseForge file.

## Release gate (manual workflow)

The stable publish workflow requires both explicit public approval and confirmation of the live nine-module Forever smoke test. It checks the exact version, tests Lua and release packaging, creates an immutable `v1.0.0` GitHub tag/release on `main`, and attaches the vetted ZIP. The CurseForge webhook publication must be verified separately.
