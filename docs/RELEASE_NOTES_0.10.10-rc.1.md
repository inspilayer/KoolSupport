# KoolSupport 0.10.10-rc.1 — Secret-aware DIES and cleaner interface

**Unpublished development candidate; no CurseForge Beta tag or upload.**

## Combat display fix

The prior 0.10.9-rc.2 condition refused to show DIES whenever Forever returned opaque combat health. With a strong tracked DoT estimate, a supported client should now render only the word DIES **inside the original target, focus or enemy nameplate health bar** using the native WoW ColorCurve Step / FontString alpha pathway.

KoolSupport first verifies nonsecret DoT tracking evidence, enemy identity, aliveness and validity without using hidden health. It then passes opaque UnitHealth into a native step curve, and passes possibly secret RGBA straight to the word's native SetTextColor. No Lua comparison, math, extraction, stringification, logging or bypass of secret health. Alpha 1 below floor(estimated remaining damage), 0 from that threshold onward, intentionally conservative. Missing or rejecting client support means no DIES; game-client confirmation is required. Existing old off-right clipping technique remains removed.

Health/damage updates and DoT expiry refresh the same bar; target/focus/nameplate changes clear old ownership. No new extra bars, no new constant polling. Historical on-frame and movable-panel modes remain explicit options, with their previous strict nonsecret lethal alerts. No other addon or Blizzard health bar is modified.

## A more useful /kool UI

- Left navigation groups existing pages into Macros, Combat, Social and Tools; one category opens at a time with compact text navigation rather than a large stack of buttons.
- KS Afflictions starts in a **Simple** view: three display-mode choices, four relevant visibility switches, native capability summary, and one refresh action.
- **Advanced settings** is a separate view for the old styles, DoT colors, icons, per-unit alerts, size and panel reset actions. Saved options and positions are preserved.

## Upgrade and test instructions

Stop WoW, back up AddOns and WTF, install exactly one KoolSupport/ directory beneath Interface/AddOns/; remove only obsolete sibling addon folders after backup. Keep SavedVariables and native macros unchanged.

Select /kool > KS Afflictions > DIES only. Verify on a target with confirmed damage-over-time ticks, a focused enemy and two visible nameplates. Observe whether text appears when the player's remaining DoTs should finish them, whether it clears after a heal, a dispel, a timer expiry, or unit change, and whether KS Threat and KS Stealth coexist. Check the in-game capability/last render reason readout. Do not infer a false-positive or false-negative from screenshot health alone because enemy numeric HP may be protected.

Offline Lua and CurseForge packaging checks must be green in PR and main. Actual Forever native ColorCurve behavior and effective text layering are still unverified. Owner approval is required for any new Beta tag.
