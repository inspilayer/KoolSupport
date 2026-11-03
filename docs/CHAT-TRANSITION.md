# KoolSupport — Principal Engineer Chat Transition

**Permanent handoff URL:** `https://github.com/inspilayer/KoolSupport/blob/main/docs/CHAT-TRANSITION.md`

**Repo:** `inspilayer/KoolSupport` (GitHub, private when last verified). **Updated:** 2026-11-03. **Intended to survive every version and chat.** Do not create new version-specific transition files; update **this path in every substantive PR**.

## 1. Startup contract for the next principal engineer

1. Read `docs/CHAT-TRANSITION.md` from current `main`; inspect newest commits/PRs and whether an open branch is ahead of main. Prefer the actual GitHub source over old conversation artifacts.
2. Read `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, addon `.toc` manifests, relevant Lua source and tests. Confirm actual branch SHA, `.toc` interface/version and release status. Never assume the last historical version is current.
3. Check project state and incoming user request. Explain what is verified, what is only planned, and what requires a live WoW client.
4. Implement in a feature branch, with isolated changes and tests; include **an update to this exact handoff file in the same PR**. Summarize verification and outstanding blockers.
5. Do not merge or release unrelated changes without a clear request. No silent destructive SavedVariables changes. Treat the owner as an experienced programmer unfamiliar with Lua and handle architectural and testing details.

**Recommended new-chat prompt:**

> Act as principal engineer for KoolSupport. Read `docs/CHAT-TRANSITION.md` from the current `main` branch of `inspilayer/KoolSupport`, then inspect the latest code, roadmap, open PRs, and tests. Continue our newest engineering work. Preserve SavedVariables and native macro integrity, our plugin dependency design, CurseForge submission boundaries, and Blizzard's secure-action restrictions. I own the player-facing vision; you own technical implementation, testing, packaging and practical technical judgment. Update this exact handoff in every substantive PR.

## 2. Product owner and working style

The product owner is a WoW player who understands software engineering, keybindings and user workflows but doesn't write Lua. Keep communication natural and collaborative. Turn examples of gameplay pain into technically sound UX. Be proactive with implementation and regression tests, but distinguish allowed macro assistance from restricted combat/input automation.

**Purpose:** KoolSupport is a general-purpose WoW macro-building platform, not a keyboard-branded tool or a bot. KS Macros ships with Base. Specialized tools are independently optional. The UI should feel like a conventional fantasy WoW addon: metallic borders, dark panels, gold text, readable grouped controls, enough spacing, and a useful landing Home page. In-game UI uses actual Blizzard widgets; browser previews are only design simulations.

## 3. Approved module hierarchy (authoritative)

```text
KoolSupport Base                  REQUIRED
└── KS Macros                     BUNDLED, ON by default; generic macro creation
    ├── KS Macro Profiles         OPTIONAL, REQUIRES Macros; JSON profile share/save/load
    └── KS Support Sessions       OPTIONAL, REQUIRES Macros; healing/focus/follow presets
KS Stealth                        OPTIONAL; Base required; Macros optional for templates
Additional KS modules             separate modules with declared dependencies
```

User-visible nesting does not mean nested WoW addon folders: each addon uses a sibling folder and `.toc` dependencies. Class-aware support presets and supportee setup belong to KS Support Sessions, **not** the generic KS Macros product. A KS Stealth resource HUD must not depend on Macro Profiles or Support Sessions.

## 4. Verified checkpoint (2026-11-03)

- **GitHub connection:** `inspilayer/KoolSupport` is accessible with push permission. Its first README commit was `80ef8571316d766540a27e9736df58a856036fba`. This modular foundation is delivered by the initial Base/KS Macros PR; verify the latest merged `main` SHA from GitHub on every new chat.
- **Dev-test note:** CI syntax-loads Lua files without executing add-on code, then runs mocked runtime tests separately.
- **New modular foundation:** `addons/KoolSupport` (Base UI + module registry + Home/Modules) and bundled `addons/KSMacros` (initial generic workshop + draft and player-confirmed macro installer). `.toc` labels `0.7.0-dev`, interface `16001` (historical client value, not newly verified). This is **an intentionally limited development scaffold**.
- **Scope limitation:** The modular scaffold does **not** yet have the complete monolithic Spellbook, Macro Suite, class-aware support profiles, saved draft migration, optional plugin installers, browser preview parity, or JSON profiles. Do not advertise it as the next release of v0.6.4.
- **Earlier release checkpoint:** The separately packaged monolithic `KoolSupport_CurseForge_v0.6.4.zip` (Nov 2, 2026) was under CurseForge review per the product owner. It has Home, supportee/name setup, class support macros (Druid/Paladin/Shaman/Priest Holy/Disc), mixed Class Presets + Custom, live spellbook scanning, Custom Builder, tooltips, draft saving and safe native macro editing. **Its submitted ZIP is frozen**. The historical development source was available in `KoolSupport_v0.6.4_Development_Package.zip` in an earlier chat; it has not yet been imported into this new GitHub repo. Obtain that exact source from the owner or prior artifact, not from invented reconstructions.
- **Old technical debt:** Monolith `.toc` version and some UI/source version labels differed; one legacy test had a hardcoded `/mnt/data/...` file path. Fix when bringing the baseline into GitHub.

## 5. Data integrity and secure macro governance

- The monolith saves **per-character** `KoolSupportDB`, including legacy `owned`, `generated`, `enabledProfiles`, `customEnabled`, `customDrafts`, `customOrder`, supportee name and class/spec. Never delete, replace or discard unknown keys.
- The new scaffold creates only namespaced `KoolSupportDB.core.enabled` and `KoolSupportDB.modules.ks_macros`. **No migration has yet been performed.** Before installing it over v0.6.4, implement idempotent migrations and tests for drafts, generated macros, ownership and session preferences.
- Macro writes only happen on explicit player interactions outside combat. On update, check existing name + previously owned body; refuse to override unrelated or manually changed macros. Validate names, 255-byte bodies and `#showtooltip` first.
- Never automate spell selection based on health/combo points, run follow loops, broadcast a keystroke across clients, or circumvent secure APIs. Optional combat UI can show permitted information; a key press still must represent a player's choice.
- Client-specific macro syntax (`/focus Name`, `@focus`, `@focustarget`, forms, spell names and new secret-value behavior) must be verified against WoW Forever, especially after beta changes.

## 6. Release/testing discipline

- `python3 scripts/check.py --package` verifies manifests and files; with Lua installed it syntax-loads all Lua and runs `tests/test_core.lua` and `tests/test_macros.lua`. The dev package contains the peer directories `KoolSupport/` and `KSMacros/` only.
- CI runs Lua 5.4 tests on pushes/PRs; Lua 5.4 is an offline approximation, **not** evidence of live Forever API compatibility. Validate native UI and macro behavior with the actual client before release.
- Existing submitted CurseForge package remains separate and unchanged until modular migration reaches equivalent behavior and user explicitly approves publishing.
- Keep upload ZIP free of tests, docs, browser mockups and unrelated images. Make no unsupported claims of CurseForge approval, in-game verification or automation capabilities.
- Before a release, review current CurseForge moderation policy and Blizzard addon guidelines, inspect the exact zip, update release notes and screenshots. Browser previews must be labeled mockups.

## 7. Current engineering next steps

1. Merge or review the initial Base/KS Macros scaffold PR after checking tests and handoff. Confirm final SHA and update checkpoint next PR if needed.
2. Import the *verbatim* v0.6.4 development source into `legacy/v0.6.4/` (or a protected archival branch), including portable tests. Avoid mixing legacy code into the new default addon ZIP.
3. Migrate full generic Macro Studio and Spellbook features into KSMacros with a stable macro-service API; add regression tests.
4. Implement idempotent backward-compatible SavedVariables migrators and separate the support workflow as optional `KSSupportSessions`.
5. Only after the foundation is stable: optional `KSMacroProfiles` JSON workflow and KS Stealth HUD.
6. Obtain real-client verification and CurseForge review decisions before publicly shipping the modular package.

### Mainline checkpoint after the foundation PR

- PR #1 merged on 2026-11-03 with squash commit `69cb19529ec3daaddeecbed3f6dd509d6cb163b1`. The offline GitHub Actions run passed. The modular foundation is now on `main`, but it is **not** a v0.6.4 upgrade.
- PR #2 establishes CI enforcement: every PR must modify this exact handoff path, or its verify workflow fails. This rule is about future engineering continuity; it does not change player-facing behavior or the CurseForge review artifact.

## 8. Required commit/PR update format

Update this document with: current branch/commit/version, what changed (and why), tests actually executed, any migration/backward compatibility impact, known problems, and precise next work. Update `docs/ROADMAP.md` if the status or dependencies change. Review PR descriptions and CI; do not treat a screenshot or source comment as production proof.
