# KoolSupport release and publishing workflow — 0.10.x

**Current engineering candidate:** `0.10.2-rc.1`. GitHub run `41723314712` already successfully created `v0.10.1-rc.1-beta`; never reuse it for the post-tag talent sprint. The next manually approved tag (after live validation) will be `v0.10.2-rc.1-beta`.

## One CurseForge listing / one ZIP

KoolSupport's single CurseForge project (ID **1780256**) distributes the **entire suite** in one install. Players do not need separate CurseForge listings or downloads for Support Sessions, Stealth or Afflictions. Keep WoW's modular architecture: every `.toc` addon lives as a sibling folder directly inside `Interface/AddOns`.

The tagged-commit CurseForge packager uses root `.pkgmeta` to create:

    KoolSupport/
    KSMacros/
    KSSupportSessions/
    KSStealth/
    KSAfflictions/

Each is a loadable WoW addon with explicit dependencies; the in-game `/kool` Module Manager can enable/disable the optional components. KS Stealth's **Talent Impacts** page is independently opt-in (off by default). Afflictions retains Joe Greive's original MIT `Vendor/LICENSE` and `Vendor/NOTICE.md`.

`scripts/check.py --package` also creates a `KoolSupport_CurseForge_Standard_0.10.1-rc.1.zip` with the same five folders. Single-plugin and Base+Macros ZIPs remain *developer isolation/test artifacts only*. **Do not upload them as separate CurseForge projects, or as alternative files to the single-suite listing.** GitHub's main publishing path is tag-only, via the CurseForge packager, rather than manual ZIP uploads.

## Existing approved public Beta

Previously published `v0.10.0-rc.1-beta` contains only Base + Macros. It stays untouched; tags and CurseForge versions are immutable checkpoints and do not retroactively pick up merged source.

## Previous candidate: 0.10.1-rc.1 (already tagged)

The original unified-bundle PR used `0.10.1-rc.1` and the owner has since tagged it as a Beta; **not stable**. Talent Impacts Sprints 2/3 are `0.10.2-rc.1` on the next mainline. Stay within 0.10.x until live Forever launch validation and fixes on or after November 4. No version tag should be pushed merely because a PR was merged; the webhook only packages tag pushes. CI alone does not prove WoW client compatibility.

### Pre-release smoke test

1. Review green GitHub PR + main CI: `python3 scripts/check.py --package`, `python3 scripts/check_curseforge_packaging.py`, and the real `BigWigsMods/packager@v2 -d` ZIP validator. Inspect exactly the five siblings, `.toc` files, vendor license and notices.
2. Confirm Forever live Interface version; `16001` is the current development assumption.
3. Back up existing `Interface/AddOns` folders and `WTF` SavedVariables. Don't overwrite hand-edited native macros or player data.
4. Install all five sibling directories from the **development** standard ZIP into the live Forever addon path and check that all dependencies load. No extra nested KoolSupport folder.
5. On supported class(es), open `/kool`: confirm the Module Manager toggles, Macro Suite 45 class presets, active learned spellbook, custom draft/builder, explicit install/overwrite rejection; check Support Sessions focus macro previews and safe manual installation.
6. Test Rogue/Druid KS Stealth nameplate combo bars (multiple visible nameplates, switching targets, zero points, combat and secret values). Test Talent Impacts OFF by default then ON, hover/click, spell icons and persistence across reload.
7. Test KS Afflictions actual DoT tick attribution, target/focus/nameplate display, lethal clipping, UI styles, vendor tracker SavedVariables and changes under `/reload`. If display/API fails, disable the affected module.
8. Report Lua errors, screenshot actual Forever UI, check combat lockdown and no automated casts or targeting. Test a safe rollback using the backed-up addon and WTF folders.

### Manual publish after approval

1. In CurseForge project **1780256**, keep **Automatic Packaging: tagged commits only**, not Package all commits.
2. Keep the existing GitHub `push` webhook active and token private. The previous Beta tag verified the delivery flow.
3. Open `https://github.com/inspilayer/KoolSupport/actions/workflows/publish-beta.yml`.
4. Choose **Run workflow** on `main`, tick the explicit release checkbox, and run only after launch smoke-test approval. It reruns all source checks and upstream packaging dry run and creates the next tag `v0.10.2-rc.1-beta` from the current check script. The action refuses duplicates or a moved main branch.
5. Inspect GitHub Webhook **Recent Deliveries** for the new tag `refs/tags/v0.10.2-rc.1-beta` and 2xx status; then CurseForge Files for the new Beta package and moderation result.
6. Publish `docs/RELEASE_NOTES_0.10.2-rc.1.md` and update project description from `docs/CURSEFORGE_DESCRIPTION.md` when ready. Approval and discoverability remain controlled by CurseForge.

The GitHub `GITHUB_TOKEN` pushes the tag; the **external webhook** is the delivery path, not a recursively triggered GitHub workflow. Do not paste CurseForge API tokens into issues, documentation or chat.

## Rollback / safety

If launch testing fails, stop release, disable the problem module (or disable the corresponding WoW addon folder), restore backed-up `Interface/AddOns` and `WTF` when appropriate, and fix the issue in a new 0.10.x candidate. Do not reuse/force-move existing release tags. Standard releases require positive live validation and project-owner approval; Beta labels are not proof of successful in-game behavior.

Do not represent browser simulations as in-client screenshots. Retain MIT upstream notices and honor Blizzard secure restrictions.
