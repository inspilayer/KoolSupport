# KoolSupport

**A modular, player-operated macro workshop for World of Warcraft: Forever.**

Current CurseForge-approved Beta: **v0.10.2-rc.1-beta** (November 4, 2026; owner-confirmed). Source candidate **0.10.4-rc.1** adds opt-in Simplified / On-frame KS Afflictions Target/Focus health-bar overlays; it is not yet published. The previously tagged 0.10.3 adds movable Target/Focus HUDs. It contains the unified five-module suite. Earlier 0.10.0 and 0.10.1 Beta tags remain untouched. **Approval is not live Forever gameplay validation**; launch-client checks are still pending.

## Modules

| Component | Install | What it does |
| --- | --- | --- |
| **KoolSupport Base** | Included | Home, navigation, settings, module manager |
| **KS Macros** | Included and on by default | Generic Macro Suite, Full Spellbook, Custom Builder |
| **KS Support Sessions** | Included; player-toggleable | Healer class presets, named focus, heals, battle rez, follow/assist |
| **KS Stealth** | Included; player-toggleable | Rogue/Feral combo-point UI on visible nameplates |
| **KS Afflictions** | Included; player-toggleable | DoT impact estimates and KS visual options (MIT DoesItDie engine) |
| **KS Macro Profiles** | Planned | JSON profile sharing, safe import/export |

Each component is a sibling addon directory in `Interface/AddOns/`; CurseForge installs the suite as one project and the in-game Module Manager controls the optional features. Use `/kool` to open the addon (subcommands: `/kool suite`, `/kool spellbook`, `/kool builder`, `/kool support`, `/kool stealth`, `/kool modules`).

The **single standard CurseForge ZIP now contains all five addon folders**: KoolSupport, KSMacros, KSSupportSessions, KSStealth and KSAfflictions. Developer-only individual ZIPs still exist for isolated testing, not separate CurseForge pages. See [architecture](docs/ARCHITECTURE.md).

## Developer setup

Run:

```shell
python3 scripts/check.py --package
```

CI uses Lua 5.4 for syntax and mocked runtime tests. `texlua` can run them locally. Output under `dist/` is an installable development package, **not** proof of live-client functionality.

## Security and player control

The addon only **writes ordinary user-triggered WoW macros** after an explicit click outside combat. It does not cast spells, automate rotations, choose finishers from combo points, broadcast keys, or control other clients. KS Stealth only renders client-provided data; it does not infer enemies or read secret combat values in Lua. Existing native macros edited by a user are protected from automatic overwrite.

## Principal engineer handoff

**[docs/CHAT-TRANSITION.md](docs/CHAT-TRANSITION.md) is canonical and must change in every substantive PR**. Read it on the current main branch before further work. See [roadmap](docs/ROADMAP.md) for migration gates and [archived monolithic source](legacy/v0.6.4/) for the previous release candidate. The archived source is never included in install ZIPs.


## KS Afflictions — optional DoT tracking module (0.10.2-rc.1)

The optional **KS Afflictions** module bundles a modified MIT-licensed tracking engine from [DoesItDie](https://github.com/swirllyman/DoesItDie) by Joe Greive. It provides KS-style **target, focus and visible-nameplate** DoT damage bars, DoT labels, spell-school colors, and an optional *estimated lethal* indicator. It requires KoolSupport Base only; it does not need DoesItDie installed separately or KS Macros.

CurseForge installs `KSAfflictions/` alongside all other KS folders; use `/kool afflictions` and the Module Manager to control it. Do not publish separate optional-module projects. The third-party license is at `addons/KSAfflictions/Vendor/LICENSE` and its modification notice at `addons/KSAfflictions/Vendor/NOTICE.md`.

**Status:** development only; first game-client validation still required. Secret health values go directly into UI widgets; no automatic spell choices or protected actions. The browser demo uses simulated encounters and is never represented as genuine game footage.

**License:** KoolSupport now uses MIT; see [LICENSE](LICENSE). Vendored DoesItDie retains its original author notice.


## Class-aware recommended macros (0.10.2-rc.1)

The bundled KS Macros module now detects the player's class and offers **five curated, optional quality-of-life macro templates for each of the nine Forever classes**. Templates use appropriate mouseover, pet, utility, stopcast, form, and modifier patterns. Spell icons are resolved from learned spells, with a native class-icon fallback. The full spellbook, generic templates and saved custom drafts remain available; the separate Support Sessions module still owns focus-based healer and follow profiles.

Recommended macros are **never installed automatically**. Players review, select and install them outside combat. If the spellbook is available, macros with unlearned requirements cannot be selected. Unverified spellbook states are labeled, and individual casts remain subject to the client's level/talent and secure macro restrictions.

**Distribution:** [CurseForge description](docs/CURSEFORGE_DESCRIPTION.md) · [release notes](docs/RELEASE_NOTES_0.10.2-rc.1.md) · [publishing checklist](docs/PUBLISHING.md). This is a release candidate, not an assertion that a live Forever client has been tested.


## CurseForge automatic packaging

Root .pkgmeta provides a verified five-folder unified distribution for CurseForge's tag-only GitHub packager. Optional modules are included in the same download and controlled in-game. CI checks the configuration and runs an upstream packager dry-run; see docs/PUBLISHING.md.

Select tagged commits only, not Package all commits. Include beta in a pre-release tag. Merging code does **not** publish to CurseForge. After November 4 live testing, the next manually approved candidate tag is `v0.10.2-rc.1-beta`. We stay on 0.10.x until validation.