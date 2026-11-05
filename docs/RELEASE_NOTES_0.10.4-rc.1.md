# KoolSupport 0.10.4-rc.1 — Simplified / On-frame Afflictions

**Status:** Unpublished development candidate; the already tagged `v0.10.3-rc.1-beta` stays immutable.

## Visual options

- **Simplified / On-frame** is an opt-in toggle in `/kool` → KS Afflictions. The existing movable Target/Focus HUDs remain the default.
- When enabled, the addon anchors a **mouse-transparent** visual layer to a compatible existing **Target or Focus health StatusBar**, with a slim estimated DoT damage strip, up to three DoT icons and the same approximate **DIES/skull** lethal indicator. It hides the larger unit panel for that unit.
- If the target or focus health StatusBar is unavailable (for example due to client API differences or UI skins), the separate movable unit panel remains the fallback.
- Nameplate indicators and their settings remain unchanged. A disabled Target or Focus hides its respective overlay.
- No WoW health bar is replaced, resized or written to. Secret health is passed only to WoW StatusBar setters; it is never compared or formatted in addon Lua.
- Prior HUD positions, preferences and the DoesItDie MIT-licensed tracker are preserved.

## Launch validation

Automated tests cover off-by-default migration behavior, stock healthbar discovery, normal/compact switching, separate target/focus views, icons, opaque health passthrough, fallback when a bar is missing, no writes to the stock bars, and module isolation. CI checks packaging all five siblings.

The actual Forever build and player UI setups must validate positioning relative to stock Target/Focus bars, interactions with other unit-frame addons, text layering, high-DPI scaling, combat events, nameplate independence and reset to movable HUD. No new public Beta is implied or authorized by this PR.
