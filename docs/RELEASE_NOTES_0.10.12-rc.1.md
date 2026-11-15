# KoolSupport 0.10.12-rc.1 — Centered DIES visibility

**Unpublished development candidate.** No CurseForge release or public Git tag is created by this change.

## KS Afflictions
- The minimalist **DIES only** display remains the default for new/default-equivalent character settings: one outlined `DIES` label at the center of the **original** target, focus, or enemy nameplate health bar. No duplicate bars, panels, icons or extra floating UI.
- Pre-warms invisible text anchors when native health bars are observable outside combat, reducing protected frame creation during combat.
- Shares a publicly observed maximum HP for at most 180 seconds **only across unit tokens with the same exact readable enemy identity** (mouseover, soft target, target, focus, nameplate). No guessing from creature name, level or unrelated enemies; max-health change invalidates cache.
- Where a client's native scalar StepCurve alpha path is rejected, tries Blizzard's native ColorCurve through `UnitHealthPercent(unit,false,curve)` and forwards opaque color directly to the FontString display sink. No Lua comparison, native Evaluate call, formatting or other manipulation of protected health/alpha.
- Lethal threshold includes exactly equal integer HP and excludes dead/zero HP, healed and expired/unproven/provisional DoT estimates. Protected unit-existence status fails closed.
- Saved advanced modes and positions are preserved. Afflictions' original MIT vendor tracker, KS Threat/Stealth and macro handling are unchanged.

## QA and limitations
Automated Lua tests cover unit attribution, 0–1 step thresholds, secret scalar and color rendering, cross-unit max evidence, explicit invalidation, UI compatibility and invisible prewarmed labels. Requires both full CI and real BigWigs single-root packaging validation.

**Actual Forever client validation is essential.** If the game never exposes the enemy's exact maximum HP for the same identity, the DoT evidence isn't reliable, or both native curve visual routes are blocked, DIES stays hidden rather than falsely promising a kill. Use `/kool dies` or the Afflictions diagnostic line while fighting to identify the gate. Do not publish an unvalidated new Beta.
