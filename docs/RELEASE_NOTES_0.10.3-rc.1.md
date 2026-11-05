# KoolSupport 0.10.3-rc.1 — Movable KS Afflictions Target/Focus HUDs

**Status:** Unpublished development candidate. **Do not** retag or modify the already approved `v0.10.2-rc.1-beta`.

## What's new

- Move the **Target DoTs** and **Focus DoTs** panels by left-dragging their title bars **outside combat**.
- Each position saves independently per character and is restored when that HUD is recreated or the UI is reloaded.
- **Reset Target** and **Reset Focus** buttons on the KS Afflictions settings page restore their original anchors beneath Blizzard's target/focus frame.
- Target/Focus frames are parented to `UIParent` and clamped to the screen; nameplate DoTs stay anchored to enemy nameplates and cannot be dragged.
- No modifications to DoT calculation, health secret handling, player macros, bundled five-module layout, third-party license, or previous saved settings.

## Verification / release gate

Run automated Lua/mock tests and packager checks (including draggable title, saved position, reset, combat refusal and default placement).
In **real Forever**, verify dragging both panels at normal and scaled UI sizes, persistence through `/reload` and relog, behavior on target/focus changes, screen clamping, click interference, and safe reset. Publish a new Beta only with explicit owner approval and a new immutable tag.
