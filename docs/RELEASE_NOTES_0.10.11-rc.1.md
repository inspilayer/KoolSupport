# KoolSupport 0.10.11-rc.1 — External tap-ownership coloring

**Development candidate. Not yet published to CurseForge.**

## KS Threat: silver means not your group's tag
- New **Silver for outside tags** per-character setting, default **ON**.
- For hostile NPCs, a verified true `UnitIsTapDenied(nameplateUnit)` takes priority over all threat colors. The mob's existing health-bar overlay turns **silver/gray**, even if you are the current aggro target or the combat-only setting is enabled.
- If the mob is tap-eligible to your group, its existing red (secure aggro), pink, violet and purple threat-state colors continue unchanged. Tap eligibility is different from threat.
- Disabling the silver override hides the KS Threat tint on those outsider-tagged mobs; it never paints such a mob as group-owned.
- Missing, secret, or nonboolean tap results leave the original Blizzard color intact. No comparison or arithmetic on secret combat values.
- Changes in unit flags and faction repaint the visible plates without background frame polling; other six-module suite behavior and native Blizzard healthbars remain untouched.
- The in-game KS Threat page now includes a fifth SILVER swatch and a `Tagged silver` diagnostic count. No private/secret unit values are logged.

## QA and distribution
- Regression tests cover group-eligible, outsider-tagged, hidden threat, disabled override, missing/secret APIs, combat gating, ownership changes, and original nameplate integrity.
- Full unit/boot/packager CI is mandatory; validate tap behavior on real Forever client in solo and grouped play before release.
- Distribution is still **one** `Interface/AddOns/KoolSupport` folder, with six internal modules and one root TOC. Prior releases and tags remain immutable.
