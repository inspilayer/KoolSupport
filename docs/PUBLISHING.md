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