# KoolSupport — Macro Workshop for World of Warcraft: Forever

**Less time writing macros. More time playing.**

KoolSupport is an in-game macro workshop with class-aware suggestions, a spellbook browser, a custom builder, and optional combat-information displays. **One CurseForge install includes the entire five-module suite.** Use the in-game Module Manager to choose the tools you want.

KoolSupport helps you **create and understand ordinary WoW macros**. It does not cast spells or control your character for you.

## Make the macros you actually want

- **45 class-aware recommendations:** Five optional quality-of-life macro ideas for each of Forever's nine classic classes — Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock, and Warrior. The Macro Suite displays recommendations for your character's class.
- **Macro Suite:** Browse **Recommended**, **General**, **Custom**, and **All**. Preview the actual macro text, select what you want, and install on your own terms.
- **Full Spellbook:** Browse learned, active spells when Forever's spellbook API makes them available. Use a spell as the starting point for a macro.
- **Custom Builder:** Write your own macros with helpers for mouseover/focus targets, modifiers, casting, stopcasting, items, equipment, pets, forms, and more. Save drafts to revisit them later.
- **Safer installs:** Explicit out-of-combat installation, native macro name/255-byte-body checks, slot preflight, and protections against overwriting unrelated or manually changed macros. No surprise macro creation on login.

Suggested macros may still require particular talents, learned spells, stances, pets, or other game conditions; KoolSupport marks unverified spell availability rather than inventing it.

## Five modules. One download.

**KoolSupport Base**  
The main window, Home, Module Manager, shared styling, and read-only **Launch Checks** for addon/API availability.

**KS Macros**  
The Macro Suite, class recommendations, Full Spellbook, Custom Builder, saved drafts, and native macro installation.

**KS Support Sessions**  
Optional healing and utility templates for player-selected support targets: named focus, focus-target healing, assist, follow, and resurrection where appropriate. Actions happen **only when you press the macro**. This module requires KS Macros.

**KS Stealth**  
Optional Rogue/Feral combo-point bars for visible nameplates **when client APIs expose the data**. It also contains **Talent Impacts**, an opt-in, read-only Druid/Rogue talent browser with six curated Druid talents and ten Rogue talents. Where available, it shows trained ranks, affected spells, learned spell ranks, documented cost changes, and optional spell-tooltip annotations. Damage examples use a **normalized 100-point baseline**; optional 200%-crit illustrations are educational examples, not your live damage. Talent Impacts and tooltip annotations are off by default.

**KS Afflictions**  
Optional target, focus, and visible-nameplate DoT tracking and estimated damage indicators. Choose **Modern KS**, **Classic WoW**, or **Minimal** styling, plus DoT colors and optional **DIES/skull** estimated-lethal markers. Estimates are not guaranteed kills. Tracking is adapted from **DoesItDie by Joe Greive (MIT)**, with its license and attribution included.

The modules share one installation but have separate in-game controls. Disabling an optional module hides its features; fully unloading its Lua may require a UI reload. **No extra CurseForge downloads are required.**

## Quick start

1. Install **KoolSupport** once with CurseForge, selecting **WoW Forever**.
2. Open the game and type **`/kool`**.
3. Visit **Modules** to configure Support Sessions, Stealth, and Afflictions.
4. Open **Macro Suite** to review recommendations or **Custom Builder** to make your own.
5. Preview and explicitly install selected macros **outside combat**.
6. Open WoW's **`/macro`** window and drag the resulting macros onto your action bars.

You can also use **`/kool suite`**, **`/kool spellbook`**, and **`/kool builder`**.

## Beta status and compatibility

**Current release: 0.10.2-rc.1-beta (approved on CurseForge, November 4, 2026).**

The suite has passed automated Lua/mock testing and CurseForge packaging checks, but **live Forever launch-client validation is still pending**. Spellbook, talent, tooltip, nameplate, and combat-value APIs can differ across client builds. If the client does not expose an expected value, the affected feature should report unavailable/unverified information rather than make it up.

For first-run troubleshooting, use **`/kool` → Launch Checks**, and enable Lua error messages with **`/console scriptErrors 1`**. When reporting a problem, include your game build, class, KoolSupport version, and any error text. If an optional display behaves unexpectedly, disable that module until it is fixed.

KoolSupport does **not** automate healing, follow loops, rotations, combat-state-based finisher selection, key broadcasting, multi-client control, or protected game actions. All native macros are player-triggered.

**Coming later:** KS Macro Profiles for versioned sharing/import of custom macro collections (not included in 0.10.2).

**Open-source / MIT:** [GitHub source, documentation, and issues](https://github.com/inspilayer/KoolSupport). Third-party DoesItDie credits and license remain in the package.
