# KoolSupport

**Class-aware macro workshop for World of Warcraft: Forever.**

KoolSupport provides an in-game interface for creating, previewing, and installing native World of Warcraft macros. The standard installation includes KoolSupport Base and KS Macros. All macro installations require an explicit player action outside combat.

## Class-aware recommended macros

The Macro Suite detects the player's class and presents five optional quality-of-life templates for each of the nine Forever classes:

- **Druid:** Shapeshifting, mouseover healing, and Entangling Roots.
- **Hunter:** Pet controls, Hunter's Mark, Mend Pet, and ranged utility.
- **Mage:** Polymorph, Counterspell, Remove Lesser Curse, and Arcane Intellect.
- **Paladin:** Mouseover healing, blessings, and Hammer of Justice.
- **Priest:** Mouseover heals, Power Word: Shield, dispels, and buffs.
- **Rogue:** Stealth, Sap, Kick, Blind, and a manual builder/finisher modifier.
- **Shaman:** Healing, Purge, Earth Shock, and Ghost Wolf.
- **Warlock:** DoT application, Fear, Death Coil, and pet support.
- **Warrior:** Charge, Taunt, Sunder Armor, Pummel, and Intercept.

Recommended, General, Custom, and All filters let players browse templates and saved drafts. Learned spells use their game-provided spell icons when available; class icons provide a fallback. If the learned-spell API is accessible, templates requiring unlearned spells are marked unavailable. When spellbook data is unavailable, templates are marked unverified rather than incorrectly asserting the spell is learned. **No templates install automatically.**

Talent, stance, level, pet, cooldown, resource, and range restrictions still apply.

## Macro Suite

Review the commands and notes for each template, select the macros you want, and explicitly install the selection outside combat. The installer validates macro names and the native 255-byte limit, checks available slots, and refuses to replace unrelated or manually changed macros.

## Full Spellbook

Browse the character's learned active spells when the supported Forever spellbook API is available. Select a spell to begin a custom macro draft. Passive and future spells are excluded when reported by the API.

## Custom Macro Builder

Write and edit native macros using organized inserts for targeting, mouseover conditions, focus, modifiers, stopcasting, form cancellation, spell casting, cast sequences, pet controls, items, equipment, and chat commands. Saved drafts can be included in the Macro Suite. The editor keeps #showtooltip on the first line and validates macro length.

## Optional modules — separate downloads

**KS Support Sessions** (requires Base + Macros): Class-aware focus-target healing, utility, resurrection, follow and assist macro templates. These are separate from the generic class recommendations. They require player key presses and do not control another game client.

**KS Stealth** (requires Base): Rogue/Feral combo-point indicators on visible nameplates when the client exposes supported data. No automated finisher selection.

**KS Afflictions** (requires Base): Configurable target, focus, and visible-nameplate DoT estimates, Modern KS styling, spell indicators, and an optional estimated lethal display. Integrates a modified MIT-licensed tracking engine from DoesItDie by Joe Greive, with the original copyright/license retained. Damage estimates are not guaranteed kills.

The planned JSON-sharing KS Macro Profiles extension is not included in this release.

## Installation

1. Install the standard ZIP so that KoolSupport and KSMacros are sibling folders directly inside Interface/AddOns.
2. Enable both addons on the character-selection addon screen.
3. Enter /kool to open the workshop.
4. Open Macro Suite to browse recommended, generic, and saved custom macros.
5. Select and review macros, then use Install selected outside combat.
6. Open /macro and drag created macros onto an action bar.

Install optional modules separately, observing their dependencies.

## Compatibility and safety

Version 0.10.0-rc.1 targets World of Warcraft: Forever. Lua syntax, mocked macro installation, module dependencies and packaging are tested, but live-client verification is still required. Native commands and spell names may differ between game builds. KoolSupport creates ordinary game macros; it does not cast spells automatically, control another client, broadcast input, select combat abilities based on health or combo points, or bypass protected actions.

**License:** MIT. Third-party source retains its original notices. Source and issue tracker: https://github.com/inspilayer/KoolSupport