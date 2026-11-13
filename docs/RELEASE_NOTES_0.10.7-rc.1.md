
# KoolSupport 0.10.7-rc.1 — KS Threat hotfix and diagnostics

**Status:** Unpublished development candidate. The tagged v0.10.6-rc.1-beta remains immutable.

## Fixed
- The original KS Threat 0.10.6 read only namePlateUnitToken. Native Blizzard plates use unitToken or GetUnit(), so some clients showed no coloring at all.
- Fall back safely across all three nameplate unit token shapes and an additional recognized health bar location.
- Track UNIT_HEALTH / UNIT_MAXHEALTH changes to keep the colored overlay synchronized with the enemy health fill without continual polling.

## New diagnostic
Open /kool > KS Threat and select **Diagnose visible plates**. It reports how many nameplates are visible, how many were colored and aggregate reasons for plates that were skipped, such as no token, not hostile, not in combat, threat unavailable or health bar not found. It does not log protected health, names, or threat values.

## Security and release governance
Existing colors, per-character opt-in, module dependencies, other six modules and immutable 0.10.6 beta are untouched. Secret combat values remain uninspected and unknown threat continues to hide the extra overlay. No tag, CurseForge upload or stable release is performed by this change. Live tank-client confirmation and explicit owner approval remain required to publish this new version.
