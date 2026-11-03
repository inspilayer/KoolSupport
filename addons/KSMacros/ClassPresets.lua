-- Reviewed, player-triggered quality-of-life templates for the nine Forever classes.
-- No focus-support profiles here; Support Sessions owns named-focus workflows.
-- Source notes: Blizzard Forever class roster and public Classic/Forever spell references.
-- Learnable spells are checked in the actual character spellbook when available.
local M=KSMacros
local function preset(id,title,group,spell,script,note,also)
  return {id=id,title=title,group=group,spell=spell,body="#showtooltip "..(spell or "").."\n"..script,
    recommended=true,note=note or "",requires=also or (spell and {spell} or {})}
end
local CLASS={
  DRUID={
    preset("KSR-D-Rejuv","Mouseover Rejuvenation","Healing","Rejuvenation",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Rejuvenation","Heals mouseover, then friendly target, otherwise self."),
    preset("KSR-D-Heal","Mouseover Healing Touch","Healing","Healing Touch",
      "/cancelform [form]\n/cast [@mouseover,help,nodead][help,nodead][@player] Healing Touch","Cancels shapeshift and heals your mouseover or self."),
    preset("KSR-D-Cat","Shift to Cat","Forms","Cat Form",
      "/cancelform [form]\n/cast Cat Form","Switch form with a single keypress where supported by the client."),
    preset("KSR-D-Bear","Shift to Bear","Forms","Bear Form",
      "/cancelform [form]\n/cast Bear Form","Requires Bear Form; Dire Bear Form is a separate learned spell."),
    preset("KSR-D-Roots","Mouseover Roots","Control","Entangling Roots",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Entangling Roots","Crowd-control a hostile mouseover without losing your target."),
  },
  HUNTER={
    preset("KSR-H-Mark","Pet Attack + Mark","Pet","Hunter's Mark",
      "/petattack [@target,harm,nodead]\n/cast [@target,harm,nodead] Hunter's Mark","Pet follows your attack command; requires an active pet."),
    preset("KSR-H-Follow","Pet Follow + Passive","Pet",nil,
      "/petpassive\n/petfollow","Recall and set pet passive (no class spell required)."),
    preset("KSR-H-Mend","Mouseover Mend Pet","Pet","Mend Pet",
      "/cast [@pet,exists,nodead] Mend Pet","Heal your active pet."),
    preset("KSR-H-Con","Mouseover Concussive Shot","Control","Concussive Shot",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Concussive Shot"),
    preset("KSR-H-Sting","Mouseover Serpent Sting","Offense","Serpent Sting",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Serpent Sting"),
  },
  MAGE={
    preset("KSR-M-Poly","Mouseover Polymorph","Control","Polymorph",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Polymorph"),
    preset("KSR-M-CStop","Interrupt with Counterspell","Control","Counterspell",
      "/stopcasting\n/cast [@mouseover,harm,nodead][@target,harm,nodead] Counterspell","Interrupts current cast before attempting Counterspell."),
    preset("KSR-M-Curse","Mouseover Remove Lesser Curse","Utility","Remove Lesser Curse",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Remove Lesser Curse"),
    preset("KSR-M-Int","Friendly Arcane Intellect","Utility","Arcane Intellect",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Arcane Intellect"),
    preset("KSR-M-Blast","Mouseover Fire Blast","Offense","Fire Blast",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Fire Blast"),
  },
  PALADIN={
    preset("KSR-P-Flash","Mouseover Flash of Light","Healing","Flash of Light",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Flash of Light"),
    preset("KSR-P-Holy","Mouseover Holy Light","Healing","Holy Light",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Holy Light"),
    preset("KSR-P-HoJ","Mouseover Hammer of Justice","Control","Hammer of Justice",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Hammer of Justice"),
    preset("KSR-P-Freed","Mouseover Blessing of Freedom","Utility","Blessing of Freedom",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Blessing of Freedom"),
    preset("KSR-P-BOP","Mouseover Blessing of Protection","Emergency","Blessing of Protection",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Blessing of Protection",
      "Avoid using on a tank without coordination; immunity to physical attacks may affect threat."),
  },
  PRIEST={
    preset("KSR-Pr-Ren","Mouseover Renew","Healing","Renew",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Renew"),
    preset("KSR-Pr-Shld","Mouseover Power Word: Shield","Emergency","Power Word: Shield",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Power Word: Shield"),
    preset("KSR-Pr-Flsh","Mouseover Flash Heal","Healing","Flash Heal",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Flash Heal"),
    preset("KSR-Pr-Dis","Friendly Dispel Magic","Utility","Dispel Magic",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Dispel Magic"),
    preset("KSR-Pr-Fort","Mouseover Fortitude","Utility","Power Word: Fortitude",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Power Word: Fortitude"),
  },
  ROGUE={
    preset("KSR-R-Stlth","Stealth without toggling off","Utility","Stealth",
      "/cast !Stealth","Prevents a repeated press from toggling Stealth off where supported."),
    preset("KSR-R-Sap","Mouseover Sap","Control","Sap",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Sap"),
    preset("KSR-R-Kick","Mouseover Kick","Control","Kick",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Kick"),
    preset("KSR-R-Blind","Mouseover Blind","Control","Blind",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Blind"),
    preset("KSR-R-Fin","Shift: Eviscerate / Sinister Strike","Offense","Sinister Strike",
      "/cast [mod:shift] Eviscerate; Sinister Strike",
      "Manual choice: hold Shift to spend points. No automatic combo-point inspection.",
      {"Sinister Strike","Eviscerate"}),
  },
  SHAMAN={
    preset("KSR-S-HWave","Mouseover Healing Wave","Healing","Healing Wave",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Healing Wave"),
    preset("KSR-S-LWave","Mouseover Lesser Healing Wave","Healing","Lesser Healing Wave",
      "/cast [@mouseover,help,nodead][help,nodead][@player] Lesser Healing Wave"),
    preset("KSR-S-Purge","Mouseover Purge","Utility","Purge",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Purge"),
    preset("KSR-S-Shock","Mouseover Earth Shock","Control","Earth Shock",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Earth Shock","An interrupt that may generate extra threat."),
    preset("KSR-S-Wolf","Ghost Wolf (no toggle off)","Forms","Ghost Wolf",
      "/cast !Ghost Wolf","Client/talent may affect mobility and cast timing."),
  },
  WARLOCK={
    preset("KSR-Wl-Agny","Mouseover Bane of Agony","Offense","Bane of Agony",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Bane of Agony","Forever uses Bane of Agony; check your learned spell name."),
    preset("KSR-Wl-Corr","Mouseover Corruption","Offense","Corruption",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Corruption"),
    preset("KSR-Wl-Fear","Mouseover Fear","Control","Fear",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Fear"),
    preset("KSR-Wl-Coil","Mouseover Death Coil","Emergency","Death Coil",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Death Coil"),
    preset("KSR-Wl-Funn","Health Funnel on pet","Pet","Health Funnel",
      "/cast [@pet,exists,nodead] Health Funnel"),
  },
  WARRIOR={
    preset("KSR-Wr-Chg","Charge + Start Attack","Movement","Charge",
      "/cast [@target,harm,nodead] Charge\n/startattack [@target,harm,nodead]","Charge conditions/range still apply."),
    preset("KSR-Wr-Taunt","Mouseover Taunt","Control","Taunt",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Taunt"),
    preset("KSR-Wr-Sund","Sunder + Start Attack","Offense","Sunder Armor",
      "/startattack [@target,harm,nodead]\n/cast [@target,harm,nodead] Sunder Armor"),
    preset("KSR-Wr-Puml","Mouseover Pummel","Control","Pummel",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Pummel",
      "Requires the appropriate stance; macro does not change your stance."),
    preset("KSR-Wr-Int","Mouseover Intercept","Movement","Intercept",
      "/cast [@mouseover,harm,nodead][@target,harm,nodead] Intercept",
      "Requires the appropriate stance, rage and range."),
  }
}
M.classTemplates=CLASS
function M:CurrentClass()
  if type(UnitClass)~="function" then return nil end
  local ok,_,token=pcall(UnitClass,"player")
  if ok and type(token)=="string" and CLASS[token] then return token end
  return nil
end
function M:GetRecommended(class)
  local current=class or self:CurrentClass()
  if not CLASS[current] then return {} end
  local items={}
  for _,value in ipairs(CLASS[current]) do items[#items+1]=value end
  return items
end
-- Resolve a spell icon from the learned spellbook, with class atlas fallback.
function M:RecommendationAvailability(item,known)
  if type(known)~="table" then return nil,"Verify learned abilities in game" end
  for _,spell in ipairs(item.requires or {}) do
    if not known[spell] then return false,"Not learned: "..spell end
  end
  return true,"Ready"
end
function M:ClassIconCoords(token)
  if CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token] then
    return CLASS_ICON_TCOORDS[token]
  end
  local atlas={
    WARRIOR={0,0.25,0,0.25},MAGE={0.25,0.49609375,0,0.25},
    ROGUE={0.49609375,0.7421875,0,0.25},DRUID={0.7421875,0.98828125,0,0.25},
    HUNTER={0,0.25,0.25,0.5},SHAMAN={0.25,0.49609375,0.25,0.5},
    PRIEST={0.49609375,0.7421875,0.25,0.5},WARLOCK={0.7421875,0.98828125,0.25,0.5},
    PALADIN={0,0.25,0.5,0.75}
  }
  return atlas[token]
end
function M:RecommendationIcon(item,known)
  local detail=known and known[item.spell]
  local id=type(detail)=="table" and detail.spellID
  if id then
    local spellFn=C_Spell and C_Spell.GetSpellTexture
    if type(spellFn)=="function" then
      local ok,texture=pcall(spellFn,id)
      if ok and texture then return texture end
    end
    if type(GetSpellTexture)=="function" then
      local ok,texture=pcall(GetSpellTexture,id)
      if ok and texture then return texture end
    end
  end
  return nil
end
