# KoolSupport 0.10.10-rc.3 — Native-percent DIES correction (development only)

**No CurseForge Beta tag or upload.**

## Actual Forever evidence
RC2 in-game diagnostic: On-frame Extras mode; 2 confirmed DoTs, 294 estimated remaining damage, enemy HP secret, attribution gate ready, native curve rejected.
That proves our player-owned damage tracker has evidence; it does not prove the enemy is lethal because its HP is secret.
Our previous direct ColorCurve EvaluateUnpacked(secret health) was marked AllowedWhenUntainted. Using it during combat from addon code was incorrect.

## RC3 implementation
- No more direct EvaluateUnpacked(secret health). All modes now call native UnitHealthPercent(unit,false,CurveObject), forwarding its result directly into FontString/Texture SetAlpha, without Lua inspecting secret HP or secret alpha.
- An absolute DoT estimate needs a known exact enemy max-HP value to become a percentage threshold. Cache only a verifiably readable UnitHealthMax for the same stable public unit key; never persist it to SavedVariables. Invalidate on target/focus/nameplate switches, UNIT_MAXHEALTH, login, and identity changes. No exact precombat max -> fail closed with max_baseline_unavailable.
- Native Step alpha: corpse 0 HP -> transparent, living HP below floor(confirmed damage) -> opaque, equal or higher -> transparent. Conservative threshold avoids a false positive.
- If UnitHealthPercent rejects the curve, report native_percent_rejected and hide DIES. The text layer never writes to original health bars or nameplates. Existing optional On-frame Extras green strip is still available, but DIES only removes it.

## Live-client acceptance
Close WoW, back up AddOns/WTF, replace only the single KoolSupport/ folder and keep SavedVariables.
Target an enemy **before combat** so the client can expose its maximum health. Apply Rip/Rake; allow at least one confirmed tick. While the same mob is still selected, type /kool dies.
Share the chat diagnostic. Expected stage may be native_percent_applied, max_baseline_unavailable, or native_percent_rejected. Native submission does not prove actual visual opacity until a live screenshot confirms it.

All Lua suites, one-root packaging and real BigWigs CurseForge dry run must pass on the PR and final main. Real Forever behavior remains unverified; no Beta publishing without owner approval. Original MIT tracker/vendor notices and macro ownership remain unchanged.
