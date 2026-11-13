# KoolSupport

**A modular, player-operated macro workshop for World of Warcraft: Forever.**

Last verified public GitHub Beta tag: **v0.10.6-rc.1-beta** (publishing workflow succeeded November 6, 2026; CurseForge moderation not independently checked). The prior 0.10.5-rc.1 Beta tag remains immutable. New source candidate **0.10.6-rc.1** adds optional KS Threat as the seventh module. Previous tags remain immutable; gameplay/client validation is required before stable release.

## Modules

| Component | Install | What it does |
| --- | --- | --- |
| **KoolSupport Base** | Included | Home, navigation, settings, module manager |
| **KS Macros** | Included and on by default | Generic Macro Suite, Full Spellbook, Custom Builder |
| **KS Support Sessions** | Included; player-toggleable | Healer class presets, named focus, heals, battle rez, follow/assist |
| **KS Stealth** | Included; player-toggleable | Rogue/Feral combo-point UI on visible nameplates |
| **KS Afflictions** | Included; player-toggleable | DoT impact estimates and KS visual options (MIT DoesItDie engine) |
| **Campfire Chat** | Included; player-toggleable | Joke, Spooky, Ramble and Edgy Joke buttons; sends one original /say line only when the Campfire Nearby buff is detected |
| **KS Macro Profiles** | Planned | JSON profile sharing, safe import/export |

Each component is a sibling addon directory in `Interface/AddOns/`; CurseForge installs the suite as one project and the in-game Module Manager controls the optional features. Use `/kool` to open the addon (subcommands: `/kool suite`, `/kool spellbook`, `/kool builder`, `/kool support`, `/kool stealth`, `/kool modules`).

The **next standard CurseForge ZIP (0.10.5 candidate) contains six addon folders**: KoolSupport, KSMacros, KSSupportSessions, KSStealth, KSAfflictions and KSCampfireChat. Developer-only individual ZIPs still exist for isolated testing, not separate CurseForge pages. See [architecture](docs/ARCHITECTURE.md).

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

## Campfire Chat — 0.10.5 candidate

Included in the same package as a separate optional module, **Campfire Chat** provides four player-clicked nearby `/say` categories: Joke, Spooky, Ramble and Edgy Joke. It has **64 original, curated, short stories** (16 per category), shuffles until each category is exhausted, and never uses remote services, other players' chat content or automatic message schedules. Exactly one short message is attempted per direct click; a **Campfire Nearby** player buff (Forever spell 1283391) is required, with fallbacks for Forever's modern/legacy aura APIs. If the aura is unavailable or the game rejects chat, nothing is queued. An eight-second local cooldown discourages chat spam. Test aura recognition and /say hardware-click rules in the real client before Beta publishing.

## KS Threat — 0.10.6 development candidate

The optional seventh module KS Threat adds tank-oriented, categorical threat colors to Blizzard enemy nameplate health bars: red (aggro status 3), pink (2), violet (1), and purple (0). It is disabled by default for each character; enable it in /kool > Modules, then open KS Threat. It is a small visual layer, not a replacement for Blizzard nameplates, cast bars, KS Afflictions or KS Stealth. It never modifies native health bar values or original colors. Only hostile, engaged enemies are colored by default; disable that restriction on the module page if desired. If Forever reports threat as secret or the health bar cannot be located safely, the original Blizzard colors remain visible. Exact hidden threat percentages are not invented. This is an unpublished source candidate, not the existing 0.10.5 Beta.

## KS Threat 0.10.7 RC — native nameplate compatibility fix

The released 0.10.6 Beta read only the optional third-party namePlateUnitToken property; Blizzard's current nameplate API exposes unitToken and GetUnit() instead. Result: the nameplate color often remained unchanged. The new unpublished 0.10.7 source candidate accepts all three documented token paths and reports how many current plates it finds and colors via the KS Threat > Diagnose visible plates button. The diagnostic categorizes skipped plates as not hostile, not fighting, missing unit token, hidden/unavailable threat or health bar, or failed overlay painting, without printing protected combat data. Overlay health also refreshes on UNIT_HEALTH / UNIT_MAXHEALTH events. It preserves all seven modules, settings, the four-state red-to-purple palette and the existing immutable 0.10.6 tag.
