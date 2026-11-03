# KoolSupport 0.10.0-rc.1 — Release Candidate

**Release type: Beta / prerelease.** Automated checks do not prove live Forever compatibility.

## Standard package
- Base and KS Macros in two sibling Interface/AddOns folders.
- Nine class-aware catalogs, five recommended quality-of-life templates per class (45 total).
- Class-detected Recommended/General/Custom/All filters.
- Learned spell icons with native class icon fallback.
- Learned-spell gating where the client spellbook is available; otherwise clearly marked unverified.
- Explicit, player-selected out-of-combat macro installation. No auto-install.
- Existing Full Spellbook, Custom Builder, saved drafts, and strict native macro overwrite safety.

## Optional downloads
- KS Support Sessions: focus-based healing, follow and utility presets (requires Base + Macros).
- KS Stealth: Rogue/Feral resource HUD (requires Base).
- KS Afflictions: DoT estimates and configurable visuals (requires Base, includes MIT DoesItDie attribution).

## Safety and testing
- No automatic gameplay, input broadcasting, hidden finisher selection or protected action workarounds.
- No deletion of legacy SavedVariables or unrelated macros.
- CI verifies Lua syntax, mock tests, manifest dependencies, and ZIP packaging.
- **Still required:** launch-client testing of actual class spell availability, icon display, native macro install/update and optional module display behavior.

### Changelog
Added class recommendations and icons, learned-spell availability, Macro Suite filters, and revised software-only CurseForge documentation. Modular optional components otherwise unchanged.