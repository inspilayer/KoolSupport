# KoolSupport

**Modular World of Warcraft macro workshop** — a development project for WoW Forever.

KoolSupport is becoming a modular addon platform: **Base + KS Macros** ship together. Macro Profiles and Support Sessions are optional Macros plugins; KS Stealth is a separate optional plugin. Everything generates **user-triggered native macros**; it does not bot, broadcast inputs between clients, or automatically decide combat actions.

**Current GitHub milestone:** `0.7.0-dev` *modular foundation*, not a full replacement for the monolithic v0.6.4 CurseForge-review build. Do **not** install it over a v0.6.4 character without first backing up SavedVariables and completing the future migration. The v0.6.4 submitted package is unchanged.

## Install the development foundation

The package created by `python3 scripts/check.py --package` contains these sibling folders:

```text
Interface/AddOns/
  KoolSupport/     # Base registry, Home and Module Manager
  KSMacros/        # Bundled generic macro workshop
```

Both are enabled by default; `KSMacros.toc` declares `## Dependencies: KoolSupport`. When installed on a supported client, use `/kool` to open the Home window or `/kool macros` to open the basic workshop.

This early workshop supports name/spell entry, common target shortcuts, editable macro text, saved drafts, and manual create/update with ownership protection. The full v0.6.4 macros feature set has **not yet been migrated**.

## Source layout

- `addons/KoolSupport` — shared Base, API v1 and WoW UI
- `addons/KSMacros` — bundled generic Macros module
- `docs/ARCHITECTURE.md` — approved dependencies, persistence and security boundaries
- `docs/ROADMAP.md` — exact stage status and upcoming migrations
- `docs/CHAT-TRANSITION.md` — **canonical principal engineer handoff, updated every substantive PR**
- `tests/` — Lua mocked-runtime tests
- `scripts/check.py` — syntax checks and distributable ZIP generation

## Verify locally

```shell
python3 scripts/check.py --package
```

With a Lua interpreter installed (`lua` or `lua5.4`), the script checks Lua compilation and runs runtime tests. CI also runs these checks. This is offline test coverage, not evidence of Forever client compatibility.

## Engineering workflow

All code changes should use a branch + PR and update **[docs/CHAT-TRANSITION.md](docs/CHAT-TRANSITION.md)** in that same PR. Consult its startup steps before editing. The main branch and handoff are the source of truth, not an earlier chat or an unrelated zip.

Project owner: WoW player with programming knowledge; engineering decisions, Lua implementation, testing and release hygiene belong with the principal engineer.
