# KoolSupport

**A modular, player-operated macro workshop for World of Warcraft: Forever.**

Development package **0.8.0-dev**. The monolithic v0.6.4 CurseForge-review package is not modified or replaced.

## Modules

| Component | Install | What it does |
| --- | --- | --- |
| **KoolSupport Base** | Included | Home, navigation, settings, module manager |
| **KS Macros** | Included and on by default | Generic Macro Suite, Full Spellbook, Custom Builder |
| **KS Support Sessions** | Optional | Healer class presets, named focus, heals, battle rez, follow/assist |
| **KS Stealth** | Optional | Rogue/Feral combo-point UI on visible nameplates |
| **KS Macro Profiles** | Planned | JSON profile sharing, safe import/export |

Each component is a sibling addon directory in `Interface/AddOns/`; optional addons declare dependencies on the components they require. Use `/kool` to open the addon (subcommands: `/kool suite`, `/kool spellbook`, `/kool builder`, `/kool support`, `/kool stealth`, `/kool modules`).

The standard download includes Base and Macros; plugins have separate ZIPs. See [architecture](docs/ARCHITECTURE.md) for dependencies and download variants.

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
