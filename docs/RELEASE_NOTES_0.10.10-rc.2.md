# KoolSupport 0.10.10-rc.2 — Evidence diagnostics and consistent DIES (development only)

**Unpublished test candidate.** No Beta tag, CurseForge upload or stable promotion.

## Based on live Forever screenshots

A fresh ~19-second Rip was visible on a very low-health Eastsea Musketeer but no DIES was rendered. The user also observed that the old green/purple advanced DoT bar remains but its DIES alert disappeared. The screenshot does **not** prove that the vendored estimator has confirmed Rip's ticks or that its remaining damage exceeds exact HP. The original tracker deliberately omits newly applied DoTs until the first observed tick; this is safe against resisted/immune casts.

## Improvements

1. **Same secret-health rendering in every display:** Centered DIES, On-frame Extras, and Movable Panels all use one guarded lethal-color code path. RC1 accidentally implemented secret-aware text only for centered mode, while advanced mode required readable health. Legacy bar layouts remain opt-in and intact. In DIES only, no second health bar, icon strip, panel or HUD is created.
2. **No false corpse labels:** the native Step ColorCurve has transparent alpha at health zero, opaque alpha from positive health 1 until strictly below the estimated conservative total, then transparent at/above floor(total). A readable confirmed dead flag still hides DIES immediately. An unavailable or secret dead/alive boolean no longer discards every otherwise eligible enemy.
3. **Diagnose the actual blocker:** run **/kool dies** in combat. The addon prints target, focus and up to two nameplates, reporting only counted confirmed DoTs, estimated remaining player-owned damage, whether health is secret (not its value), an attribution/evidence gate reason and the visual result stage. The simple /kool > Combat > KS Afflictions screen also shows the selected target report after Refresh display check. A 0-DoT report can mean the tracker is still awaiting its first tick or could not confirm the spell.
4. **No weakening of Forever protections:** secret health is never compared, formatted, logged or extracted. It is fed only to the native ColorCurve, with returned secret RGBA forwarded to native FontString:SetTextColor or Texture:SetVertexColor. Unsupported/rejected operations fail closed. No invented lethal signal and no continuous heavy polling.

## Install / in-game validation

Exit WoW, back up AddOns and WTF, replace one Interface/AddOns/KoolSupport folder and keep SavedVariables. Remove only obsolete top-level sibling module folders after backup, if present.

Set DIES only in /kool > Combat > KS Afflictions. Apply Rip, allow **at least one real periodic tick** before checking, then use **/kool dies** while that enemy is selected. Capture the chat output and the health bar in one screenshot. Compare with advanced mode to verify the optional green bar remains deliberately optional. Test focus and multiple nameplates, healing/expiration/target changes and KS Threat/Stealth coexistence.

**Expected interpretation:** gate=no_estimate means no confirmed DoT damage; gate=ready + display=native_curve_applied means the native secret-data visual was submitted, not that Lua can know its visible alpha. display=secret_curve_rejected / secret_text_rejected or unsupported_frame shows an actual client limitation to investigate. Exact Forever behavior is still unverified until tested in game.

Release governance: green Lua and real CurseForge packager dry-run required in PR and final main; single KoolSupport install folder, vendored MIT notices, user settings and macros unchanged. Do not tag or publish a new Beta without owner authorization.
