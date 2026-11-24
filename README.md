# KoolSupport

**A modular, player-operated macro workshop for World of Warcraft: Forever.**

Last confirmed GitHub Beta tag: **v0.10.14-rc.1-beta**. **1.0.0** is staged for a stable release. Public publishing remains gated on the owner's live Forever smoke-test confirmation and the protected publishing workflow.

## Modules

| Component | Install | What it does |
| --- | --- | --- |
| **KoolSupport Base** | Included | Home, navigation, settings, module manager |
| **KS Macros** | Included and on by default | Generic Macro Suite, Full Spellbook, Custom Builder |
| **KS Support Sessions** | Included; player-toggleable | Healer class presets, named focus, heals, battle rez, follow/assist |
| **KS Stealth** | Included; player-toggleable | Rogue/Feral combo-point pips plus optional personal Energy bar on the current target's overhead nameplate; dedicated Pip Designer and saved visual settings |
| **KS Afflictions** | Included; player-toggleable | Minimal centered DIES text on known-lethal native health bars; optional advanced displays (MIT DoesItDie engine) |
| **Campfire Chat** | Included; player-toggleable | Joke, Spooky, Ramble and Edgy Joke buttons; sends one original /say line only when the Campfire Nearby buff is detected |
| **KS Quest Checker** | Included; player-toggleable | Search quest names and IDs, then check Blizzard's character completion flag; optionally uses a separately installed QuestieDB for a full quest-name index |
| **Guilty Forever** | Included; player-toggleable | Private ignore reasons, first-name + surname enemy tags, saved grudge ledger and party/target reminders |
| **Sleeping Bag Navigator** | Included; off by default | Draggable guide for the Cozy Sleeping Bag quest chain, including faction routes, hidden-object steps, and map-pin fallback |
| **KS Combat Text Studio** | Included; **off by default** in 1.1 development | Native Blizzard combat text dock, four animated text lanes, presets, fonts, crit emphasis, draggable placement and event diagnostics |
| **KS Macro Profiles** | Planned | JSON profile sharing, safe import/export |

**Starting with 0.10.8, only the `KoolSupport/` folder goes directly inside `Interface/AddOns/`.** All ten module sources are packaged in `KoolSupport/Modules/`; the in-game Module Manager still controls optional features. Use `/kool` to open the addon (subcommands: `/kool suite`, `/kool spellbook`, `/kool builder`, `/kool support`, `/kool stealth`, `/kool modules`, `/kool quest`).

The **1.0.0 release ZIP contains one top-level folder**, `KoolSupport`, with all ten modules nested. Developer ZIPs use that same layout. See [architecture](docs/ARCHITECTURE.md).

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

Root .pkgmeta provides a single-root, six-module unified distribution for CurseForge's tag-only GitHub packager. Optional modules are included in the same download and controlled in-game. CI checks the configuration and runs an upstream packager dry-run; see docs/PUBLISHING.md.

Select tagged commits only, not Package all commits. Include beta in a pre-release tag. Merging code does **not** publish to CurseForge. After November 4 live testing, the next manually approved candidate tag is `v0.10.2-rc.1-beta`. We stay on 0.10.x until validation.

## Campfire Chat — 0.10.5 candidate

Included in the same package as a separate optional module, **Campfire Chat** provides four player-clicked nearby `/say` categories: Joke, Spooky, Ramble and Edgy Joke. It has **64 original, curated, short stories** (16 per category), shuffles until each category is exhausted, and never uses remote services, other players' chat content or automatic message schedules. Exactly one short message is attempted per direct click; a **Campfire Nearby** player buff (Forever spell 1283391) is required, with fallbacks for Forever's modern/legacy aura APIs. If the aura is unavailable or the game rejects chat, nothing is queued. An eight-second local cooldown discourages chat spam. Test aura recognition and /say hardware-click rules in the real client before Beta publishing.

## KS Threat — 0.10.6 development candidate

The optional seventh module KS Threat adds tank-oriented, categorical threat colors to Blizzard enemy nameplate health bars: red (aggro status 3), pink (2), violet (1), and purple (0). It is disabled by default for each character; enable it in /kool > Modules, then open KS Threat. It is a small visual layer, not a replacement for Blizzard nameplates, cast bars, KS Afflictions or KS Stealth. It never modifies native health bar values or original colors. Only hostile, engaged enemies are colored by default; disable that restriction on the module page if desired. If Forever reports threat as secret or the health bar cannot be located safely, the original Blizzard colors remain visible. Exact hidden threat percentages are not invented. This is an unpublished source candidate, not the existing 0.10.5 Beta.

## KS Threat 0.10.7 RC — native nameplate compatibility fix

The released 0.10.6 Beta read only the optional third-party namePlateUnitToken property; Blizzard's current nameplate API exposes unitToken and GetUnit() instead. Result: the nameplate color often remained unchanged. The new unpublished 0.10.7 source candidate accepts all three documented token paths and reports how many current plates it finds and colors via the KS Threat > Diagnose visible plates button. The diagnostic categorizes skipped plates as not hostile, not fighting, missing unit token, hidden/unavailable threat or health bar, or failed overlay painting, without printing protected combat data. Overlay health also refreshes on UNIT_HEALTH / UNIT_MAXHEALTH events. It preserves all seven modules, settings, the four-state red-to-purple palette and the existing immutable 0.10.6 tag.


## Single-folder installation (0.10.8 RC)

Extract the standard ZIP into `World of Warcraft/_forever_/Interface/AddOns/` to get exactly one new folder: `KoolSupport/`. It includes `KoolSupport.toc`, Base Lua and `Modules/{KSMacros,KSSupportSessions,KSStealth,KSAfflictions,KSCampfireChat,KSThreat}/`. The game loads only the Base TOC, in the same module order as before; the `/kool` in-game Module Manager retains its settings, dependencies and default-off KS Threat flag. The GitHub source remains separated in `addons/<module>` for engineering clarity, but distribution is nested by the packager.

**Important upgrade from 0.10.7 or earlier:** Exit WoW completely; back up `Interface/AddOns` and `WTF`. Delete the **six obsolete top-level module folders** (`KSMacros`, `KSSupportSessions`, `KSStealth`, `KSAfflictions`, `KSCampfireChat`, `KSThreat`) from `Interface/AddOns` before extracting 0.10.8; otherwise old addon code may load twice and register modules twice. Keep `KoolSupport/` and replace its files. Do **not** delete or replace `WTF` — the per-character `KoolSupportDB` remains under the same host addon and should persist.

The legacy **account-wide Afflictions tracker** data (`KSAfflictionsTrackerDB`) previously lived in `WTF/Account/<account>/SavedVariables/KSAfflictions.lua`; it will now be saved under `.../SavedVariables/KoolSupport.lua` because WoW keys saved-variable files to the physical addon folder. **Back up this original file before migration.** For continuity, with WoW closed and with no existing `.../SavedVariables/KoolSupport.lua`, make a **copy** of `KSAfflictions.lua` named `KoolSupport.lua` in the same directory. If `KoolSupport.lua` already exists, don't overwrite it; merge only the `KSAfflictionsTrackerDB` assignment manually after backing up both files. The older file is not deleted automatically. The module's own `## SavedVariables: KSAfflictionsTrackerDB` declaration is carried into the unified TOC.

0.10.8 is development-only until its real packager and Forever client are verified; it does not publish a new CurseForge tag automatically.

## KS Afflictions — 0.10.9 Centered DIES

**Default: no bars, floating windows, DoT strips, or extra spell icons.** When KS can attribute tracked remaining DoT/bleed damage to an enemy and compare it to **readable, nonsecret** health, a mouse-transparent outlined `DIES` word appears over the *original* target, focus, or visible enemy nameplate health bar. If health becomes secret or any estimate/attribution is unsupported, the word does **not** appear; the previous wide clipped StatusBar cannot supply a reliable exact lethal condition. This deliberate fail-closed behavior must be validated in the real Forever client.

Use `/kool` > KS Afflictions to switch between **Centered DIES** (default), **On-frame Extras**, and **Movable Panels**. Historical advanced options and prior per-character panel positions remain available. The old automatic `onFrame=false` default does not reliably distinguish someone who deliberately clicked OFF, so default-equivalent saves migrate to centered mode; an explicit new displayMode persists on subsequent upgrades. The full client-install guide and limitations are in [0.10.9 development notes](docs/RELEASE_NOTES_0.10.10-rc.3.md). **No new CurseForge tag is published by this development change.**

**Live screenshot follow-up (0.10.10-rc.3):** Old saved `onFrame=true` preferences intentionally select **On-frame Extras**, which still shows green/purple DoTs strips; choose `/kool` > KS Afflictions > **Centered DIES** for *no extra bars*. The settings page now displays the active mode. Legacy modes no longer use the off-right giant clipping/statusbar lethal label; any advanced-mode DIES/skull is centered and uses the same conservative nonsecret-health predicate. Secret combat health may mean no alert. See [RC2 notes](docs/RELEASE_NOTES_0.10.10-rc.3.md).

## 0.10.10 development notes: combat DIES and streamlined /kool

Combat health often becomes secret in Forever; 0.10.9 conservative code therefore suppressed DIES. This candidate attempts an explicitly native **secret-aware ColorCurve** that sets the centered DIES text's alpha directly from opaque health. Addon Lua never compares/reads that secret value. Only a verified, still-active, attributable DoT estimate is eligible for the visual; any unsupported client, expired estimate or missing enemy association hides it. Live Forever tests remain mandatory before publishing. See [0.10.10 RC notes](docs/RELEASE_NOTES_0.10.10-rc.3.md).

The configuration UI no longer opens with a wall of controls. /kool navigation is grouped by category, and KS Afflictions offers a small default page plus Advanced settings for the old optional bars and positions. Saved mode preferences, every module, macros, tracker history and the one-folder installation are preserved.


### No DIES even with Rip? 0.10.10-rc.3 diagnostic

A full Rip timer on an enemy does **not** confirm the tracker has observed a tick; its MIT DoesItDie-derived logic intentionally excludes an unverified freshly applied DoT. This release fixes a mismatch where advanced green/purple bar modes did not support secret-health lethal text, and where secret dead/alive booleans could suppress the centered label.

For evidence, select the enemy and type **/kool dies** during a fight. Target/focus and up to two visible nameplates report the count of confirmed DoTs, your estimated damage, protected/readable health classification (NEVER numeric enemy health), and the gate/display reason. The simple Afflictions configuration has a selected-target diagnostic line under **Client support**. See [RC2 test notes](docs/RELEASE_NOTES_0.10.10-rc.3.md). If "no_estimate", let Rip tick once and recheck; if "native_curve_applied" but text remains invisible, client support/visual layering still needs investigation. No false positive is forced.

### RC3: confirmed secret-curve blocker

The real Forever diagnostic reported 2 DoTs, 294 predicted damage, gate ready, and secret_curve_rejected. The prior direct curve-evaluator call was restricted for tainted callers. RC3 instead uses native UnitHealthPercent(unit,false,curve) and an allowed alpha setter, but only if the enemy's exact maximum health was cached while readable before combat. No cached max or unsupported native method means no DIES, never a fabricated lethal label. Target an enemy before combat, then use /kool dies after Rip ticks; check for max baseline ready and native_percent_applied. See [RC3 development notes](docs/RELEASE_NOTES_0.10.10-rc.3.md). No Beta tag/publishing.


## KS Threat — silver tagged-mob override (0.10.11 RC)

When you enable KS Threat, its new **Silver for outside tags** toggle defaults to ON. Enemy nameplates whose mob is already tagged by a player outside your party/group appear silver/gray, **even if you have aggro**. Known player/group-eligible mobs keep the original red → pink → violet → purple threat palette. This is based on Forever's `UnitIsTapDenied` API, not threat. If the game hides or does not expose a valid tap status, KS Threat leaves Blizzard's own nameplate color instead of guessing. The KS Threat page shows a fifth SILVER swatch and a `Tagged silver` diagnostic counter. This is an unpublished `0.10.11-rc.1` source candidate pending client confirmation; the one-folder installation format and saved module preferences are unchanged.


## Centered DIES reliability — 0.10.12 RC

The **DIES only** display is still the default for new/default-equivalent Afflictions profiles. 0.10.12 improves its ability to appear in combat without displaying extra HUDs: hidden text anchors are prepared before combat; a verified enemy maximum HP can now be reused across mouseover, softenemy and other unit references **only when their exact public identity matches**; and clients rejecting the scalar `UnitHealthPercent` alpha curve can try a native ColorCurve/FontString color path. The numeric comparison of secret combat HP remains forbidden, so neither pathway guesses. If the enemy wasn't observable before combat, the DoT estimate is untrusted, or Forever rejects native curve rendering, the label intentionally remains absent. It appears only on the appropriate original health bar and clears on nonlethal/healed/expired outcomes.

For live troubleshooting select `/kool` → KS Afflictions → **DIES only**, then `Refresh display check` or use `/kool dies` (if supported by your client) while fighting. Inspect `estimated`, `gate`, `max baseline` and `display` rather than assuming a low health bar means a verified lethal total. You can also inspect `On-frame extras` and `Movable panels` if they were explicitly saved previously. No auto-publishing; 0.10.12 is a dev test build pending real Forever screenshots.


## New Base feature: Time Since XP (0.10.13 development build)

KoolSupport can now gently remind you to **get out of town and earn XP**. It detects your real experience-bar increases and level-ups; after **15 minutes without XP**, it shows one short center-screen message and local chat notice, then repeats at 30, 45, 60 minutes, etc. It never sends messages to other players, moves you, or automates gameplay. Repeated XP_UPDATE events with no increase do not reset the timer. The tracker **starts fresh after each login or UI reload** (not overnight), and skips max-level characters. Long pauses generate at most one reminder when the game resumes.

Open `/kool` → **Tools → Time Since XP**, or use the **Time Since XP** button on Home. See elapsed session time, your next 15-minute reminder, an ON/OFF toggle (enabled by default **per character**) and a Test notification. The test won't change the timer. This lives in Base—there is no new AddOns directory or seventh module. Unpublished `0.10.13-rc.1` requires live Forever verification before a new Beta tag.


## KS Afflictions: secret-HP DIES fix (0.10.14 development candidate)

A live `/kool dies` test on 0.10.13 showed an enemy with **3 tracked DoTs and 381 damage remaining** but no `DIES`, due solely to `max_baseline_unavailable`. New 0.10.14 no longer requires the enemy's readable maximum HP for the default text-only label. Instead, it adapts the original MIT DoesItDie native clipped-health-bar visual comparison to put only a **small centered DIES word** over the existing target, focus or nameplate health bar when your DoTs are about to finish the mob. The extra StatusBar is transparent and only drives text placement; no additional health bars or windows are shown.

This is a *native visual threshold*, not a Lua health comparison: a tiny fragment of the word may slide in within ~0.38% before the estimate equals HP, while the full word is visible when it reaches lethal. When no DoTs remain, the text is hidden. Use `/kool dies` to confirm `display native_clip_applied` even when the max baseline is missing; that stage means the comparator was installed, **not that the target is already dead**. If unsupported by the actual Forever client's native clipping API, the addon falls back to older curves/known-readable health or hides the label. CI cannot substitute for in-game confirmation. Release still requires approval.

## KS Quest Checker (0.10.15-rc.1 development)

Use `/kool quest` or **Tools → Quest Checker**. Enter a quest name (e.g. *The Prophecy of Mosh'aru*) or numeric ID (`3527`), select a result and read **Completed / turned in**, **Not flagged completed**, or **Unknown** based exclusively on the current character's Blizzard quest flag. The name catalog is broader when the separately installed [QuestieDB](https://github.com/Questie/QuestieDB) is available; without it, the panel searches locally known and game-known quest names, and exact numeric IDs still work. No quest is auto-accepted, turned in, or modified. Recently selected IDs are kept per character. QuestieDB's code/database is not included in KoolSupport's ZIP.


## KS Stealth movable combo HUD (0.10.15-rc.2 development)

Go to `/kool` → **Combat → KS Stealth**. Toggle **HUD: ON**, click **Unlock / move HUD**, drag the **DRAG COMBO POINTS** label to the desired position, then **Lock HUD position**. Optional independent controls resize or reset the HUD. It shows five gold native combo-point pips for your current target on Druid/Rogue, and disappears when target is lost while locked. Unlocked mode always shows empty positioning pips. Its visibility and position are independent from nameplate combo pips. All settings persist per character and cannot be changed while in combat. Combo values are forwarded directly to native Blizzard StatusBars without Lua comparing restricted secret values. Live Forever verification required before Beta.


## Road to 1.0 public

RC1 establishes the compact slate/gold UI kit, smaller sidebar typography, neutral button treatments and unified styling in the main workshop and module pages. RC2 will address in-game visual review notes. Do not publish stable until the 8-module Forever smoke test, combat/resource rendering, macro ownership protection, SavedVariables persistence, packaging/license validation and product-owner acceptance all pass. See [roadmap](docs/ROADMAP.md) and [transition](docs/CHAT-TRANSITION.md).


## 1.1.0-rc.1 — Combat Text Studio (development)

1.0.0 remains the public stable baseline. This 1.1 release candidate adds an **optional, disabled-by-default** Combat Text Studio module under Combat. After enabling, choose **Native** to move Blizzard's ordinary combat text, or **Studio** for four custom animated text lanes. Presets: Classic, Minimal, Arcade, Fountain, Cascade, Zen; 12 animation styles, five built-in client fonts, four palettes, editable font size/crit multiplier/outline/speed/lifetime/spread/opacity/max messages. Unlock and drag positions or type `/kct test` to preview; `/kct status` summarizes the event stream. No external fonts are bundled. The module restores Blizzard anchor/CVar changes when disabled.

**Forever limitation:** its public event APIs do not give reliable full attribution of outgoing player-only hits, so the optional UNIT_COMBAT lane explicitly shows observed target events, not guaranteed personal damage. Other lanes rely on the Forever client's COMBAT_TEXT_UPDATE availability and secret-safe values. The module does not alter damage calculations or cast spells. Live client verification is required before a 1.1 stable public update.
