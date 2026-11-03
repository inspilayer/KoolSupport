# Publishing KoolSupport 0.10.0-rc.1

## Correct ZIP

Upload KoolSupport_CurseForge_Standard_0.10.0-rc.1.zip. The archive must contain exactly two top-level folders:

    KoolSupport/        Base framework and KoolSupport.toc
    KSMacros/           Macro workshop, class templates and KSMacros.toc

Do not upload the all-modules development ZIP as the standard addon. Optional plugin ZIPs are separate uploads and list their own dependencies. Do not include browser previews, tests, legacy source or documentation in game ZIPs.

## Before uploading

1. Verify GitHub Actions and python3 scripts/check.py --package pass.
2. Inspect all ZIP entries and verify .toc versions and the live Forever Interface number (currently development value 16001).
3. Back up WTF SavedVariables and existing addon folders; never erase player macros.
4. Live-test /kool, all four suite filters, class detection, unlearned spell marking, native icon results and player-triggered create/update/ownership rejection.
5. Confirm SavedVariables survive /reload and test at least one player per class before describing the class coverage as live-verified.
6. If client testing is incomplete, publish only as Beta / release candidate, not stable. Keep any existing pending moderation submission unchanged.

## CurseForge author workflow

1. Open the existing KoolSupport project in the CurseForge author dashboard.
2. Files -> Upload File; choose the verified KoolSupport_CurseForge_Standard_0.10.0-rc.1.zip file.
3. Select the correct World of Warcraft: Forever game version if offered, and Beta as release type while live-client validation remains incomplete. Never use an unrelated game version to work around a missing selector.
4. Include docs/RELEASE_NOTES_0.10.0-rc.1.md as the file changelog.
5. Update the project Long Description using docs/CURSEFORGE_DESCRIPTION.md.
6. Suggested one-line summary: Class-aware WoW macro workshop with recommended presets, learned spellbook, custom builder, and optional support modules.
7. Submit for moderation and verify status. Approval and publication are controlled by CurseForge.

Do not present simulated browser screenshots or AI-modified showcase images as in-game captures; clearly disclose them. Third-party DoesItDie code used by optional Afflictions must retain the original MIT copyright and license.

## GitHub prerelease

After the reviewed commit is on main, optionally create tag v0.10.0-rc.1 and a GitHub pre-release, attach the standard ZIP and distinct optional module ZIPs, and include the changelog. GitHub publishing is separate from CurseForge approval.

## Rollback

Disable the new addon and restore the backed-up previous addon folders and WTF SavedVariables. Do not delete macros or claim the migration is fully verified without client testing.

## CurseForge built-in GitHub packaging (tagged commits only)

Source Code: GitHub. Repository URL: https://github.com/inspilayer/KoolSupport
Automatic Packaging: The packager will package any new tagged commits it sees when code is pushed.

Root .pkgmeta moves the two standard addon folders out of addons/ into WoW's sibling AddOns folders, and excludes optional addons and development sources. scripts/check_curseforge_packaging.py validates the manifest, while GitHub CI uses BigWigsMods/packager@v2 with -d to build and inspect a real ZIP without publishing.

Never enable Package all commits: that would generate alpha files for ordinary engineering pushes. Do not create a tag automatically after merging a PR. CurseForge treats tags containing the literal word beta as Beta; a tag named only v0.10.0-rc.1 may instead become Release. Example approved manual beta tag: v0.10.0-rc.1-beta.

Before tagging, check PR CI, live Forever Interface number and a player-tested macro installation. Keep API/webhook tokens in author settings or GitHub Secrets, not source. Nothing in this change tags, uploads or publishes a file.

CurseForge project visibility (unlisted vs public) is separate from packaging. Unlisted projects are still accessible to users with the link.

## One-click beta tagging from GitHub Actions

The manual GitHub Action named **Publish KoolSupport Beta (CurseForge tag)** lives at `.github/workflows/publish-beta.yml`. It does **not** run on merges; the project owner explicitly launches it from **GitHub → Actions → Publish KoolSupport Beta (CurseForge tag) → Run workflow → main**, ticks the beta-approval checkbox, and runs it.

The action runs the complete Lua test suite and offline packaging tests, dry-runs the actual BigWigs packager, validates the two-folder ZIP, checks that main did not advance during verification, and pushes exactly one immutable tag based on the tested VERSION in `scripts/check.py`, e.g. `v0.10.0-rc.1-beta`. It refuses duplicate tags and unknown/non-RC versions.

**External webhook required:** In CurseForge set automatic packaging to tagged commits, save it, generate a Webhooks API token in the CurseForge account, and configure `https://github.com/inspilayer/KoolSupport/settings/hooks` with the payload URL described in the official CurseForge Automatic Packaging support guide. The URL contains a private token. Enter it **only in GitHub webhook settings**, not in documentation, a chat, code or GitHub Actions logs. Use the Push event and leave the webhook active. Verify a 2xx delivery in Recent Deliveries when the tag is pushed.

GitHub's built-in `GITHUB_TOKEN` is used only to push the tag; it does not call CurseForge APIs or host secrets. GitHub Actions triggered by the resulting tag may not run due to GitHub's `GITHUB_TOKEN` recursion limitation; **the external CurseForge push webhook is the intended delivery mechanism**. Publishing still depends on webhook configuration and moderation. A green GitHub tag action alone is not proof CurseForge accepted a file.

No beta tag has been pushed as part of adding this workflow. Run it only after the owner approves pre-release distribution and understands live client compatibility remains unverified.