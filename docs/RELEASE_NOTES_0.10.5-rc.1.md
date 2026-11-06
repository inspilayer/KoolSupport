# KoolSupport 0.10.5-rc.1 — Campfire Chat

**Status: development candidate.** No CurseForge submission or public Git tag has been created for 0.10.5. Previous `v0.10.4-rc.1-beta` remains immutable.

## Campfire Chat — a new optional sixth module

Campfire Chat joins the existing one-install KoolSupport suite as `KSCampfireChat`, requiring Base only. Open `/kool` → **Campfire Chat** and choose:

- **Joke:** harmless campfire groaners
- **Spooky:** tiny mysterious tales with warm or funny twists
- **Ramble:** ridiculous observations about the world, weather and nature
- **Edgy Joke:** cheeky in-world tavern jokes, not insults toward real-world groups

Each category contains **16 original, prewritten lines**, for 64 total. They fit one nearby chat message (240 bytes or less), and randomized draw bags avoid immediate repeats until a category has cycled. The lines are bundled in the addon; no AI service, outside text, or network connection is used.

## Campfire and chat safety

Only a direct button click may request exactly one nearby `/say`. A confirmed **Campfire Nearby** player aura (Forever spell ID **1283391**) is mandatory, with guarded `C_UnitAuras` and `UnitBuff`/`UnitAura` fallbacks; missing/unknown aura access fails closed. A local **8-second cooldown** prevents rapid repeats. No chat on login, targeting, combat, buff changes or timer; no queued lines or retries. Messages are never sent in PARTY, GUILD, YELL, WHISPER or addon channels.

Live Forever testing must verify the current aura APIs, buff state, hardware-event restrictions on outdoor `SAY`, and in-game UI behavior. The addon never bypasses protected chat rules, automatically broadcasts, reads other players' messages or writes macros/SavedVariables.

## Distribution

Same CurseForge project and **six sibling addon folders**: KoolSupport, KSMacros, KSSupportSessions, KSStealth, KSAfflictions and KSCampfireChat. No separate CurseForge project, publisher action or new Beta tag is implied by merging code. Existing DoesItDie MIT license and notices remain in the package.
