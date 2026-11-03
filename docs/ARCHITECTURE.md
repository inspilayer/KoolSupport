# KoolSupport modular architecture

**Approved direction, updated 2026-11-03.** This document describes product dependencies and the initial 0.7.0-dev foundation. Features still being migrated are identified as planned; do not assume they already exist in the modular build.

## Product and physical addon hierarchy

```text
KoolSupport Base                              required, bundled
└── KS Macros                                  required default download, bundled
    ├── KS Macro Profiles                      optional, requires KS Macros
    └── KS Support Sessions                    optional, requires KS Macros
KS Stealth                                    optional, requires Base
  └── optional macro packages via KS Macros    soft integration
```

Separate WoW addons reside in **sibling directories** beneath `Interface/AddOns/`. Logical parent/child relationships are expressed via `.toc` dependencies, not nested directories. The standard KoolSupport download must include *both* `KoolSupport/` and `KSMacros/` with Macros enabled by default. Users should not have to install a second package to write normal macros.

## Responsibilities

- **Base** owns Home, the module registry, module/page gating, user settings, shared UI, startup messages, and lifecycle hooks. Base must never become a spell-casting or native macro editing library.
- **KS Macros** owns the generic macro workshop, spellbook integration, native macro install/update safety, drafts, macro templates and extensibility. The 0.7.0-dev scaffold presently implements only the initial workshop and safe installer; advanced v0.6.4 functionality is not yet migrated.
- **KS Macro Profiles** will own user-reviewed, versioned profile import/export via copy-paste JSON. WoW addons cannot access arbitrary JSON files from the filesystem at runtime. JSON is **not** the SavedVariables format.
- **KS Support Sessions** will own character supportee selection, named `/focus` creation, focus/focustarget heals/offense, class support presets, follow/mobility macro creation and resurrection templates. This is *not* input broadcasting or automated multiboxing.
- **KS Stealth** will own informational Rogue/Feral resource HUD and class utilities. The HUD should function without KS Macros; if Macros is present, Stealth can contribute templates.

## API v1 (development)

`KoolSupport:RegisterModule({id, title, apiVersion=1, defaultEnabled, requires, onEnable, onDisable})` registers a module after Core loads. `KoolSupport:RegisterPage({id, title, moduleId, build(parent, core)})` registers its UI page. `GetModule`, `IsModuleEnabled`, `SetModuleEnabled`, `CanOpenPage`, `ShowPage`, `GetDatabase` and `IsInCombat` are the base APIs. Plugin APIs will be versioned rather than accessing another module's private tables. A disabled module is hidden from navigation; already-loaded Lua remains resident until reload.

### Module loading / dependency behavior

- Base `.toc` loads before `KSMacros` because Macros declares `## Dependencies: KoolSupport`.
- `KSMacroProfiles` and `KSSupportSessions` must hard-depend on both `KoolSupport, KSMacros` when built.
- `KSStealth` requires KoolSupport and may use `## OptionalDeps: KSMacros`.
- Changing module toggles happens outside combat; enabling a child is blocked while its prerequisite is disabled.
- Disabling a prerequisite is blocked while an enabled dependent still requires it. Disabling never deletes saved macros or SavedVariables.
- This foundation does not yet implement LoadOnDemand; introduce only after testing the target WoW client's APIs.

## Persistence and migration

Existing v0.6.4 per-character `KoolSupportDB` contains `owned`, `generated`, `enabledProfiles`, `customEnabled`, `customDrafts`, `customOrder`, supportee name/class/spec and other keys. **Do not delete, rename, or clobber these.** The new foundation writes under `KoolSupportDB.core.enabled` and `KoolSupportDB.modules.ks_macros` and leaves unknown legacy keys alone. This is not a completed migration: moving the old drafts, ownership fingerprints and support-session state requires versioned idempotent migrators with tests for collisions and hand edits.

The first development package is **not an in-place upgrade** of v0.6.4. Never recommend installing it as a replacement until legacy feature parity and data migration have been proved. Snapshot and preserve old SavedVariables first.

## Security and native macro rules

- Only create or edit native macros on explicit player clicks, outside combat.
- Do not generate state-calculated secure casts or bypass WoW secure actions.
- No unattended healing, combo-point-based spell selection, cross-client input broadcasting, auto-follow loops or bot-like behavior.
- Verify owned macro fingerprints before edits. If a player edits a macro, refuse to overwrite silently.
- Respect 255-byte macro bodies and 16-byte names for the presently targeted macro APIs; re-verify against the actual client at release.
- Keep `#showtooltip` as the first line in generated bodies.
- Live Forever API compatibility (including `/follow`, `@focus`, C_SpellBook, combat restrictions, and GameTooltip) remains unverified.

## Release boundaries

- v0.6.4 is the historical monolithic CurseForge-review candidate; **do not change the submitted ZIP**.
- 0.7.0-dev is a new modular development foundation, not a verified release or feature-complete successor.
- Interface value `16001` is taken from v0.6.4 and must be checked against the client before publishing.
- Standard addon ZIP: ONLY sibling `KoolSupport/` and `KSMacros/`. Exclude tests, browser HTML previews and documentation from the installable addon zip.
- Browser previews are mockups, not real in-game screenshots. CurseForge moderation and release approval cannot be assumed.
