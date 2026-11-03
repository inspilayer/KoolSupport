# KoolSupport

A modular, player-operated World of Warcraft macro workshop.

**Development status:** The repository is being initialized. The existing **v0.6.4 CurseForge submission is unchanged and remains separate** from modular development.

## Product structure

- **KoolSupport Base** — shared shell, settings, navigation and module registry.
- **KS Macros** — bundled generic macro-building foundation, enabled by default.
- **KS Macro Profiles** — optional child of KS Macros; portable JSON profile import/export.
- **KS Support Sessions** — optional child of KS Macros; named-focus support macro presets.
- **KS Stealth** — optional sibling requiring Base, with macro integrations when KS Macros is installed.

The source of truth for the next engineer is [docs/CHAT-TRANSITION.md](docs/CHAT-TRANSITION.md), which **must be updated in every substantive PR** and when release/checkpoint status changes.

## Project status

This repository started empty on November 3, 2026. The base/module scaffold is the first development milestone, **not a verified in-game release**. The current released/submitted monolithic package must not be replaced until a fully tested migration is ready.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/ROADMAP.md](docs/ROADMAP.md) for design and next steps once the initial foundation PR lands.
