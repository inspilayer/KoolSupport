-- KoolSupport 0.2.1: explicit, read-only macro templates.
-- Each entry is a NATIVE MACRO requiring the user to press its key.
KSSupportProfiles = {}

local function spell(spellName, unit, cancelForm)
  local lines = {"#showtooltip " .. spellName}
  if cancelForm then lines[#lines+1] = "/cancelform [form]" end
  local condition = {
    focus="[@focus,help,nodead]",
    enemy="[@focustarget,harm,nodead]",
    dead="[@focus,help,dead,nocombat]",
    brez="[@focus,help,dead]",
    self="[@player]",
  }
  lines[#lines+1] = "/cast " .. (condition[unit] and (condition[unit] .. " ") or "") .. spellName
  return table.concat(lines, "\n")
end

local function direct(spellName, unit, cancelForm)
  return spell(spellName,unit,cancelForm)
end

local function mk(id, caption, group, body, default, note)
  return {name="KS-"..id, caption=caption, group=group, body=body, default=default ~= false, note=note or ""}
end

local melee = {WARRIOR=true,ROGUE=true,HUNTER=true,DRUID=true,PALADIN=true}
local caster = {PRIEST=true,MAGE=true,WARLOCK=true,SHAMAN=true}
local function focusFollow(playerClass)
  if playerClass == "DRUID" then
    return table.concat({
      "#showtooltip Travel Form",
      "/stopmacro [@focus,noexists]",
      "/cancelform [swimming,noform:2][indoors,noform:3][outdoors,noform:4]",
      "/cast [swimming] !Aquatic Form; [indoors] !Cat Form; [outdoors] !Travel Form",
      "/follow focus",
    },"\n")
  end
  if playerClass == "SHAMAN" then
    -- Do not assume Instant Ghost Wolf: that requires a specific talent investment.
    return "#showtooltip Ghost Wolf\n/stopmacro [@focus,noexists]\n/cast [outdoors,nocombat] !Ghost Wolf\n/follow focus"
  end
  return "#showtooltip\n/stopmacro [@focus,noexists]\n/follow focus"
end

local function focusButton(name)
  -- Setting focus by a named party/raid member does not change current target.
  -- This is a player-triggered secure macro; all support actions remain focus based.
  return "#showtooltip\n/focus " .. name
end

local function build(playerClass,spec,recipientClass,recipientName)
  local list={}
  local isShiftClass = playerClass == "DRUID" or playerClass == "SHAMAN"
  local function add(id,caption,group,body,enabled,note)
    list[#list+1] = mk(id,caption,group,body,enabled,note)
  end
  add("Session","1. Set session focus", "Core", focusButton(recipientName), true, "Sets focus to the named group member without targeting them. All other buttons use @focus or @focustarget.")
  add("Track","2. Follow + mobility", "Core", focusFollow(playerClass), true,
      "One physical press to request following. Travel/Ghost Wolf may require another press.")
  if playerClass=="DRUID" then
    add("Quick","Rejuvenation (HoT)","Healing",spell("Rejuvenation","focus",true),true)
    add("Big","Healing Touch","Healing",spell("Healing Touch","focus",true),true)
    add("Hot","Regrowth","Healing",spell("Regrowth","focus",true),true)
    add("Shield","Swiftmend (talent)","Healing",spell("Swiftmend","focus",true),false,"Requires Swiftmend talent and heal-over-time effects.")
    add("OhNo","Nature's Swiftness + Healing Touch","Emergency",
      "#showtooltip Healing Touch\n/cancelform [form]\n/cast Nature's Swiftness\n/cast [@focus,help,nodead] Healing Touch", false,"Talent required; test GCD behavior.")
    add("Cleanse","Abolish Poison","Utility",spell("Abolish Poison","focus",true),true)
    add("Flex","Remove Curse","Utility",spell("Remove Curse","focus",true),false)
    add("CC","Entangling Roots on focus enemy","Control",spell("Entangling Roots","enemy",true),true)
    add("Attack","Moonfire on focus enemy","Offense",spell("Moonfire","enemy",true),true)
    add("Rez","Rebirth (battle rez)","Emergency",spell("Rebirth","brez",true),true)
    add("Mana","Innervate focus","Utility",spell("Innervate","focus",true),false)
    add("Buff","Mark of the Wild","Utility",spell("Mark of the Wild","focus",true),true)
    add("Guard","Bash (Bear only)","Control", "#showtooltip Bash\n/cast [form:1,@focustarget,harm,nodead] Bash",false,
      "Requires Bear/Dire Bear form and melee range.")
    add("Special","Feral Charge (form conditional)","Control",
      "#showtooltip Feral Charge\n/cast [form:1,@focustarget,harm,nodead][form:3,@focustarget,harm,nodead] Feral Charge",false)
    add("Special2","Revive (out of combat)","Utility",spell("Revive","dead",true),false)
  elseif playerClass=="PALADIN" then
    local buff = melee[recipientClass] and "Blessing of Might" or "Blessing of Wisdom"
    if recipientClass=="DRUID" or recipientClass=="PALADIN" then buff="Blessing of Kings" end
    add("Quick","Flash of Light","Healing",spell("Flash of Light","focus"),true)
    add("Big","Holy Light","Healing",spell("Holy Light","focus"),true)
    add("Hot","Holy Shock (talent)","Healing",spell("Holy Shock","focus"),false,"Requires Holy Shock (Holy talent).")
    add("Shield","Blessing of Protection","Emergency",spell("Blessing of Protection","focus"),false,
      "Do NOT use casually on a tank: it prevents physical attacks and can disrupt threat/tanking.")
    add("OhNo","Lay on Hands","Emergency",spell("Lay on Hands","focus"),true,"Extremely long cooldown.")
    add("Cleanse","Cleanse","Utility",spell("Cleanse","focus"),true,"Learned later; use Purify at lower level.")
    add("Flex","Purify","Utility",spell("Purify","focus"),false)
    add("CC","Hammer of Justice on focus enemy","Control",spell("Hammer of Justice","enemy"),true,"Melee-range stun.")
    add("Attack","Judgement on focus enemy","Offense",spell("Judgement","enemy"),true)
    add("Rez","Redemption (out of combat)","Utility",spell("Redemption","dead"),true)
    add("Mana","Divine Favor (talent)","Utility",spell("Divine Favor","self"),false)
    add("Buff",buff.." on focus","Utility",spell(buff,"focus"),true,"Suggested blessing for recipient class; change if preferred.")
    add("Guard","Blessing of Freedom","Emergency",spell("Blessing of Freedom","focus"),true)
    add("Special","Blessing of Sacrifice","Emergency",spell("Blessing of Sacrifice","focus"),false)
    add("Special2","Light's Vigil (talent)","Healing",spell("Light's Vigil","focus"),false,"31-point Holy talent in Forever.")
  elseif playerClass=="SHAMAN" then
    local totem = melee[recipientClass] and "Strength of Earth Totem" or "Mana Spring Totem"
    add("Quick","Lesser Healing Wave","Healing",spell("Lesser Healing Wave","focus",true),true)
    add("Big","Healing Wave","Healing",spell("Healing Wave","focus",true),true)
    add("Hot","Chain Heal","Healing",spell("Chain Heal","focus",true),true)
    add("Shield","Riptide (talent)","Healing",spell("Riptide","focus",true),false,"31-point Restoration talent in Forever.")
    add("OhNo","Nature's Swiftness + Healing Wave","Emergency",
      "#showtooltip Healing Wave\n/cancelform [form]\n/cast Nature's Swiftness\n/cast [@focus,help,nodead] Healing Wave",false,"Talent required; check GCD/instant behavior.")
    add("Cleanse","Cure Poison","Utility",spell("Cure Poison","focus",true),true)
    add("Flex","Cure Disease","Utility",spell("Cure Disease","focus",true),false)
    add("CC","Earth Shock on focus enemy","Control",spell("Earth Shock","enemy",true),true,"Interrupt; causes significant threat.")
    add("Attack","Purge focus enemy","Offense",spell("Purge","enemy",true),true)
    add("Rez","Ancestral Spirit (out of combat)","Utility",spell("Ancestral Spirit","dead",true),true)
    add("Mana","Mana Tide Totem (talent)","Utility",spell("Mana Tide Totem","self",true),false,"Restoration talent; placed at your alt's position.")
    add("Buff",totem,"Utility",spell(totem,"self",true),true,"Recipient-class-inspired totem; placed at your alt's feet.")
    add("Guard","Tremor Totem","Utility",spell("Tremor Totem","self",true),true,"Fear/charm/sleep countermeasure.")
    add("Special","Earthbind Totem","Control",spell("Earthbind Totem","self",true),false)
    add("Special2","Grounding Totem","Utility",spell("Grounding Totem","self",true),false)
    add("AltHeal","Earth Shield (if learned)","Healing",spell("Earth Shield","focus",true),false,"Optional: verify this is a castable talent in your build.")
  elseif playerClass=="PRIEST" then
    add("Quick","Flash Heal","Healing",spell("Flash Heal","focus"),true)
    add("Big","Greater Heal","Healing",spell("Greater Heal","focus"),true)
    add("Hot","Renew","Healing",spell("Renew","focus"),true)
    add("Shield","Power Word: Shield","Emergency",spell("Power Word: Shield","focus"),true)
    if spec=="Discipline" then
      add("OhNo","Penance (talent)","Emergency",spell("Penance","focus"),false,"Discipline 21-point talent; channeled heal.")
      add("Mana","Power Infusion (talent)","Utility",spell("Power Infusion","focus"),false,"More valuable when supporting a caster.")
      add("AltHeal","Penance on focus enemy","Offense",spell("Penance","enemy"),false)
    else
      add("OhNo","Binding Heal (talent)","Emergency",spell("Binding Heal","focus"),false,"Holy 16-point talent. Heals you and focus.")
      add("Mana","Prayer of Mending (talent)","Healing",spell("Prayer of Mending","focus"),false,"Holy 31-point talent; bounce heal.")
      add("AltHeal","Prayer of Healing (target party)","Healing",spell("Prayer of Healing","focus"),false,
        "Forever heals the selected target's party, not necessarily your own.")
    end
    add("Cleanse","Dispel Magic (friendly)","Utility",spell("Dispel Magic","focus"),true)
    add("Flex","Abolish Disease","Utility",spell("Abolish Disease","focus"),false)
    add("CC","Psychic Scream (self AoE)","Control",spell("Psychic Scream","self"),true,"Fear affects enemies near your Priest, not near your main.")
    add("Attack","Dispel Magic (enemy purge)","Offense",spell("Dispel Magic","enemy"),false)
    add("Rez","Resurrection (out of combat)","Utility",spell("Resurrection","dead"),true)
    add("Buff","Power Word: Fortitude","Utility",spell("Power Word: Fortitude","focus"),true)
    add("Guard","Fear Ward","Emergency",spell("Fear Ward","focus"),true,"Baseline from level 20 in Forever.")
    add("Special","Fade (self)","Emergency",spell("Fade","self"),true)
    add("Special2","Shackle Undead (focus enemy)","Control",spell("Shackle Undead","enemy"),false,
      "Only works on Undead; breaks on damage.")
  end
  return list
end

function KSSupportProfiles.Build(playerClass,spec,recipientClass,recipientName)
  return build(playerClass,spec,recipientClass,recipientName)
end
