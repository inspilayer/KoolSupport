# KoolSupport 0.10.2-rc.1 — Talent Impacts Sprints 2/3

**Status:** Beta candidate for post-2026-11-04 Forever live testing. NOT a published CurseForge release by this PR.

## Single-download suite

Continues unified `KoolSupport` CurseForge package (project 1780256): KoolSupport Base, KS Macros, KS Support Sessions, KS Stealth and KS Afflictions as five sibling Interface/AddOns directories. The current `v0.10.1-rc.1-beta` tag remains unchanged.

## New in Talent Impacts

- Read-only committed Forever talent rank scanning via C_ClassTalents and C_Traits; invalid, staged or unavailable data displays as **unverified**.
- Learned active spell scan uses the highest identified spell rank; optional ability costs from C_Spell.GetSpellPowerCost outside combat.
- Accurate modifier types for normalized damage %, talent cost changes, critical chance, cooldowns and documented conditional effects, with broader curated coverage: 6 Druid, 10 Rogue talents.
- Optional native spell tooltip annotations (read-only, feature-detected modern TooltipDataProcessor); optional `[KS talents]` markers on KS Full Spellbook entries.
- Paged Talent Impacts native UI with talent hover/click, opt-in annotations and optional 200%-crit illustrations, manual refresh and guarded talent/spell change invalidation.
- Updated Nov 2 Forever Rogue talent changes and corrected Flawless Execution Energy discount to 10.

**Math limits:** "100 → 110" is a normalized example, NOT current hit damage. "Crit at 200%" is a simple illustration, NOT an actual calculated crit. Any estimated "without this talent" cost uses the current readable cost and documented reduction, and is clearly approximate. No talent rank or number is fabricated when the API is unavailable.

## Safety and release gate

No automatic casts, gameplay decisions, target data, secret health/combo calculations, secure UI edits or user macro overwrites. All new preferences default OFF and coexist with prior SavedVariables. Keep five-folder CurseForge packaging and upstream MIT notice intact.

Automated Lua, mocked API/unit/UI tests and packager dry-run must pass before merge; real Forever testing of traits, spellbook, tooltip hooks, combat lockdown, 16001 Interface and persistence on Nov 4 is still required. No stable tag or public upload is implied. Once the owner explicitly approves a new Beta, use the manually initiated GitHub Publish Beta workflow to create `v0.10.2-rc.1-beta`.
