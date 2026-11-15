# KoolSupport 0.10.14-rc.1 — Centered DIES without enemy maximum HP

**Unpublished development build. Not released to CurseForge.**

## Root cause confirmed by a player's actual client

KoolSupport 0.10.13's `/kool dies` showed **three tracked DoTs, 381 remaining**, a READY evidence gate, and secret health, but displayed `max_baseline_unavailable`. The tracked DoT model was working, but our old native-percent rendering demanded a nonsecret maximum HP, which Forever didn't expose.

## Fix

We adapted the MIT DoesItDie upstream **native clipped StatusBar kill icon** method to render **only a small DIES word** in the center of each supported existing target, focus or enemy nameplate health bar. A transparent, hidden-extra-chrome statusbar receives secret current health as its *native* maximum and validated remaining DoT damage as its value. Its fill position moves an outlined DIES FontString through a small clipping window. **There is no Lua comparison, division, logging or inference of secret HP and no max-HP cache requirement.** The full DIES text appears when the native health/damage fill reaches the lethal threshold. Approximately 0.38% before lethal, a few pixels of text can begin sliding in; native clipping cannot expose a secret exact comparison as a true/false value.

Additional behavior: independent target/focus/nameplate indicators, no original Blizzard bar changes, full cleanup on unavailable/expired DoTs or unit switches, hidden prewarm when possible and guarded setup for late nameplates. Retain exact readable-health comparisons and optional native percent-curve fallback for incompatible clients. Diagnostics report `native_clip_applied` and **max baseline not needed** when this path runs; the status means the visual comparator is installed, not proof that a mob is currently lethal.

## Quality and release gate

New secret-HP and secret-max regression tests cover independent tracked damage and native frame integrity, the existing centered mode, and six-module single-folder packaging. Run complete Lua tests and the real BigWigs/CurseForge dry-run packager on PR and main. An actual Forever test with a target at/under estimated DoT damage is required before a separate owner-approved CurseForge release. Do not overwrite any existing tag.
