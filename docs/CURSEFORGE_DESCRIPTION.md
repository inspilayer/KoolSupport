# KoolSupport

**Class-aware macro workshop for World of Warcraft: Forever.**

KoolSupport provides an in-game interface for creating, previewing, and installing native World of Warcraft macros. The single CurseForge install bundles KoolSupport Base, KS Macros, KS Support Sessions, KS Stealth and KS Afflictions. The modules retain separate in-game controls; macro installation always requires an explicit player action outside combat.

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

## Included optional modules — one download

**KS Support Sessions** (requires Base + Macros): Class-aware focus-target healing, utility, resurrection, follow and assist macro templates. These are separate from the generic class recommendations. They require player key presses and do not control another game client.

**KS Stealth** (requires Base): Rogue/Feral combo-point indicators on visible nameplates when the client exposes supported data, plus an **opt-in** Druid/Rogue Talent Impacts browser covering 6 Druid and 10 Rogue talents. The browser can read trained talent ranks and learned spell ranks (when Forever APIs permit), show supported cost reductions and **normalized damage examples**, and optionally append read-only KS notes to spell tooltips. Crit illustrations are optional and are not guaranteed real hit values. No automated finisher selection.

**KS Afflictions** (requires Base): Configurable target, focus, and visible-nameplate DoT estimates, Modern KS styling, spell indicators, and an optional estimated lethal display. Integrates a modified MIT-licensed tracking engine from DoesItDie by Joe Greive, with the original copyright/license retained. Damage estimates are not guaranteed kills.

The planned JSON-sharing KS Macro Profiles extension is not included. The historical 0.10.0-rc.1-beta package contained Base + Macros only. The five-module suite was tagged as v0.10.1-rc.1-beta; Talent Impacts Sprints 2/3 are the next 0.10.2 candidate.

## Installation

1. Install KoolSupport once through CurseForge. It places all five folders as siblings directly inside Interface/AddOns.
2. Enable KoolSupport and KS Macros. Support Sessions, Stealth and Afflictions are included and can be individually enabled or disabled in the in-game Module Manager.
3. Enter /kool to open the workshop.
4. Open Macro Suite to browse recommended, generic, and saved custom macros.
5. Select and review macros, then use Install selected outside combat.
6. Open /macro and drag created macros onto an action bar.

No separate CurseForge project or download is needed for an optional module. The in-game Module Manager controls each optional module while preserving saved preferences.

## Compatibility and safety

Next candidate 0.10.2-rc.1 targets World of Warcraft: Forever and remains 0.10.x Beta until launch-client validation. Lua syntax, mocked macro installation, module dependencies and packaging are tested, but live-client verification is still required. Native commands and spell names may differ between game builds. KoolSupport creates ordinary game macros; it does not cast spells automatically, control another client, broadcast input, select combat abilities based on health or combo points, or bypass protected actions.

**License:** MIT. Third-party source retains its original notices. Source and issue tracker: https://github.com/inspilayer/KoolSupport