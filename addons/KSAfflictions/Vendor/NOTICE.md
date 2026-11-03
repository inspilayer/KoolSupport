# Third-party attribution — DoesItDie

**Upstream:** https://github.com/swirllyman/DoesItDie
**Author:** Joe Greive
**License:** MIT (see `Vendor/LICENSE`)
**Imported:** 2026-11-03, upstream `main` as retrieved from GitHub.

KoolSupport's optional **KS Afflictions** module includes the DoesItDie spell/tick tracking engine and locale parsing, not its standalone UI or image assets. The tracking file is lightly adapted to:
- use `KSAfflictionsTrackerDB` instead of `DoesItDieDB` so installation alongside DoesItDie cannot overwrite its saved data;
- remove the independent `/did` command handler;
- supply a no-op display compatibility shim and KS-native bar rendering.

All original author notices and the MIT license remain included. The engine's DoT damage predictions are estimates, not guaranteed kills. The original source is MIT-licensed; KS modifications also use MIT. KoolSupport does not claim upstream endorsement.

**Data security:** DoesItDie learns from player spellcasts and observed periodic ticks. Its calculations may not be valid for every Forever spell, rank, talent, raid modifier, or interaction; test against the actual client. No automatic spellcasts or secure-action bypasses.
