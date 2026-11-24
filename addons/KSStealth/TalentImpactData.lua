-- Curated World of Warcraft: Forever 2026-11-02 talent-to-ability facts.
-- These descriptions/percentages are static, not player combat telemetry.
-- Only TalentResolver.lua can mark a rank as confirmed from C_Traits.
KSStealth=KSStealth or {}
local S=KSStealth
local function pct(values) return {kind="damage_pct",values=values} end
local function cost(values,resource) return {kind="cost_flat",values=values,resource=resource} end
local function critical(values) return {kind="crit_chance",values=values} end
local function cooldown(values) return {kind="cooldown_flat",values=values} end
S.TalentImpacts={
 DRUID={
  {
   id="ferocity",name="Ferocity",tree="Feral Combat",maxRank=5,
   effect="Reduces the Rage or Energy costs of supported Feral abilities by 1 per rank.",
   abilities={"Maul","Primal Bite","Swipe","Claw","Rake"},
   modifiers={Maul=cost({1,2,3,4,5},"RAGE"),["Primal Bite"]=cost({1,2,3,4,5},"RAGE"),
     Swipe=cost({1,2,3,4,5},"RAGE"),Claw=cost({1,2,3,4,5},"ENERGY"),
     Rake=cost({1,2,3,4,5},"ENERGY")},
  },
  {
   id="feral_instinct",name="Feral Instinct",tree="Feral Combat",maxRank=3,
   effect="Increases Swipe damage by 10/20/30%; also improves Prowl detection resistance.",
   abilities={"Swipe","Prowl"},modifiers={Swipe=pct({10,20,30})},
  },
  {
   id="shredding_attacks",name="Shredding Attacks",tree="Feral Combat",maxRank=3,
   effect="Reduces Shred Energy by 6/12/18 and Lacerate Rage by 1/2/3.",
   abilities={"Shred","Lacerate"},
   modifiers={Shred=cost({6,12,18},"ENERGY"),Lacerate=cost({1,2,3},"RAGE")},
  },
  {
   id="savage_fury",name="Savage Fury",tree="Feral Combat",maxRank=2,
   effect="Increases Claw, Rake, Shred, Maul and Swipe damage by 5/10%.",
   abilities={"Claw","Rake","Shred","Maul","Swipe"},
   modifiers={Claw=pct({5,10}),Rake=pct({5,10}),Shred=pct({5,10}),
     Maul=pct({5,10}),Swipe=pct({5,10})},
  },
  {
   id="natural_instinct",name="Natural Instinct",tree="Feral Combat",maxRank=2,
   effect="Increases melee critical damage bonus by 10/20% and healing from Intellect.",
   abilities={"Claw","Rake","Shred","Maul","Swipe","Primal Bite"},
   modifiers={}, -- cannot infer total critical multiplier from tooltip wording
  },
  {
   id="rend_and_tear",name="Rend and Tear",tree="Feral Combat",maxRank=5,
   effect="Conditionally increases melee damage against Bleeding targets. Bleed state is not read.",
   abilities={"Claw","Shred","Maul","Primal Bite","Swipe"},modifiers={},
  },
 },
 -- Curated Forever rank data, not Classic talents. Numeric values reference the
 -- client-tree snapshots and do not imply that an unconfirmed talent is trained.
 -- https://playfulls.com/talent-calculator/shaman/talents (23 Nov 2026)
 SHAMAN={
  {
   id="convection",name="Convection",tree="Elemental",maxRank=5,
   effect="Reduces mana spent on Shock, Lightning Bolt and Chain Lightning spells by 2/4/6/8/10%.",
   abilities={"Lightning Bolt","Chain Lightning","Earth Shock","Flame Shock","Frost Shock"},
   modifiers={["Lightning Bolt"]={kind="cost_pct",values={2,4,6,8,10},resource="MANA"},
    ["Chain Lightning"]={kind="cost_pct",values={2,4,6,8,10},resource="MANA"},
    ["Earth Shock"]={kind="cost_pct",values={2,4,6,8,10},resource="MANA"},
    ["Flame Shock"]={kind="cost_pct",values={2,4,6,8,10},resource="MANA"},
    ["Frost Shock"]={kind="cost_pct",values={2,4,6,8,10},resource="MANA"}},
  },
  {
   id="concussion",name="Concussion",tree="Elemental",maxRank=5,
   effect="Increases Lightning Bolt, Chain Lightning and Earth Shock damage by 1/2/3/4/5%.",
   abilities={"Lightning Bolt","Chain Lightning","Earth Shock"},
   modifiers={["Lightning Bolt"]=pct({1,2,3,4,5}),
    ["Chain Lightning"]=pct({1,2,3,4,5}),["Earth Shock"]=pct({1,2,3,4,5})},
  },
  {
   id="reverberation",name="Reverberation",tree="Elemental",maxRank=5,
   effect="Reduces Shock cooldowns by 0.2/0.4/0.6/0.8/1.0 sec.",
   abilities={"Earth Shock","Flame Shock","Frost Shock"},
   modifiers={["Earth Shock"]=cooldown({0.2,0.4,0.6,0.8,1}),
    ["Flame Shock"]=cooldown({0.2,0.4,0.6,0.8,1}),
    ["Frost Shock"]=cooldown({0.2,0.4,0.6,0.8,1})},
  },
  {
   id="elemental_alacrity",name="Elemental Alacrity",tree="Elemental",maxRank=3,
   effect="Shortens Lightning Bolt and Chain Lightning cast times by 0.17/0.33/0.50 sec.",
   abilities={"Lightning Bolt","Chain Lightning"},
   modifiers={["Lightning Bolt"]={kind="cast_flat",values={0.17,0.33,0.5}},
    ["Chain Lightning"]={kind="cast_flat",values={0.17,0.33,0.5}}},
  },
  {
   id="call_of_flame",name="Call of Flame",tree="Elemental",maxRank=3,
   effect="Adds 5/10/15% Fire Totem, Flame Shock and Fire Nova damage; Flame Shock lasts 3/6/9 sec longer.",
   abilities={"Flame Shock","Fire Nova","Magma Totem","Searing Totem"},
   modifiers={["Flame Shock"]=pct({5,10,15}),["Fire Nova"]=pct({5,10,15})},
  },
  {
   id="improved_lightning_shield",name="Improved Lightning Shield",tree="Enhancement",maxRank=3,
   effect="Increases damage from Lightning Shield orbs by 5/10/15%.",
   abilities={"Lightning Shield"},
   modifiers={["Lightning Shield"]=pct({5,10,15})},
  },
  {
   id="improved_ghost_wolf",name="Improved Ghost Wolf",tree="Enhancement",maxRank=2,
   effect="Reduces Ghost Wolf cast time by 1/3 sec and permits indoor use.",
   abilities={"Ghost Wolf"},
   modifiers={["Ghost Wolf"]={kind="cast_flat",values={1,3}}},
  },
  {
   id="improved_healing_wave",name="Improved Healing Wave",tree="Restoration",maxRank=5,
   effect="Reduces Healing Wave casting time by 0.1/0.2/0.3/0.4/0.5 sec.",
   abilities={"Healing Wave"},
   modifiers={["Healing Wave"]={kind="cast_flat",values={0.1,0.2,0.3,0.4,0.5}}},
  },
 },
 -- https://talentsforever.com/mage/talents (18 Nov hotfixes)
 MAGE={
  {
   id="accelerant",name="Accelerant",tree="Fire",maxRank=5,
   effect="Reduces Fireball, Frostfire Bolt and Arcane Wrath cast times by 0.1 sec per rank.",
   abilities={"Fireball","Frostfire Bolt","Arcane Wrath"},
   modifiers={Fireball={kind="cast_flat",values={0.1,0.2,0.3,0.4,0.5}},
    ["Frostfire Bolt"]={kind="cast_flat",values={0.1,0.2,0.3,0.4,0.5}},
    ["Arcane Wrath"]={kind="cast_flat",values={0.1,0.2,0.3,0.4,0.5}}},
  },
  {
   id="incineration",name="Incineration",tree="Fire",maxRank=5,
   effect="Adds 2/4/6/8/10 percentage points crit chance to Fire Blast, Ice Lance, Arcane Blast and Scorch.",
   abilities={"Fire Blast","Ice Lance","Arcane Blast","Scorch"},
   modifiers={["Fire Blast"]=critical({2,4,6,8,10}),
    ["Ice Lance"]=critical({2,4,6,8,10}),
    ["Arcane Blast"]=critical({2,4,6,8,10}),Scorch=critical({2,4,6,8,10})},
  },
  {
   id="improved_frostbolt",name="Improved Frostbolt",tree="Frost",maxRank=5,
   effect="Reduces Frostbolt casting time by 0.1/0.2/0.3/0.4/0.5 sec.",
   abilities={"Frostbolt"},
   modifiers={Frostbolt={kind="cast_flat",values={0.1,0.2,0.3,0.4,0.5}}},
  },
  {
   id="improved_cone_of_cold",name="Improved Cone of Cold",tree="Frost",maxRank=3,
   effect="Increases Cone of Cold damage by 12/23/35%.",
   abilities={"Cone of Cold"},modifiers={["Cone of Cold"]=pct({12,23,35})},
  },
  {
   id="shatter",name="Shatter",tree="Frost",maxRank=3,
   effect="Against Frozen targets, all spells gain 17/33/50 percentage points crit chance. Target condition is not evaluated.",
   abilities={"Frostbolt","Ice Lance","Cone of Cold","Frostfire Bolt"},
   modifiers={}, -- Requires Frozen target, never advertise an unconditional crit increase.
  },
  {
   id="arcane_geometry",name="Arcane Geometry",tree="Arcane",maxRank=2,
   effect="Increases range of Arcane spells by 3/6 yards; this is a range change, not damage.",
   abilities={"Arcane Missiles","Arcane Blast","Arcane Wrath"},
   modifiers={["Arcane Missiles"]={kind="range_yards",values={3,6}},
    ["Arcane Blast"]={kind="range_yards",values={3,6}},
    ["Arcane Wrath"]={kind="range_yards",values={3,6}}},
  },
 },
 -- https://talentsforever.com/hunter/talents (10 Nov hotfixes)
 HUNTER={
  {
   id="improved_stings",name="Improved Stings",tree="Marksmanship",maxRank=3,
   effect="Serpent Sting damage +6/13/20%; Viper Sting cooldown -2/4/6 sec; Scorpid Sting duration +15/30/45 sec.",
   abilities={"Serpent Sting","Viper Sting","Scorpid Sting"},
   modifiers={["Serpent Sting"]=pct({6,13,20}),
    ["Viper Sting"]=cooldown({2,4,6}),
    ["Scorpid Sting"]={kind="duration_flat",values={15,30,45}}},
  },
  {
   id="efficiency",name="Efficiency",tree="Marksmanship",maxRank=5,
   effect="Reduces mana costs of Shots, Stings and melee abilities by 3/6/9/12/15%.",
   abilities={"Arcane Shot","Multi-Shot","Serpent Sting","Raptor Strike","Mongoose Bite"},
   modifiers={["Arcane Shot"]={kind="cost_pct",values={3,6,9,12,15},resource="MANA"},
    ["Multi-Shot"]={kind="cost_pct",values={3,6,9,12,15},resource="MANA"},
    ["Serpent Sting"]={kind="cost_pct",values={3,6,9,12,15},resource="MANA"},
    ["Raptor Strike"]={kind="cost_pct",values={3,6,9,12,15},resource="MANA"},
    ["Mongoose Bite"]={kind="cost_pct",values={3,6,9,12,15},resource="MANA"}},
  },
  {
   id="improved_arcane_shot",name="Improved Arcane Shot",tree="Marksmanship",maxRank=5,
   effect="Reduces Arcane Shot cooldown by 0.3/0.6/0.9/1.2/1.5 sec; does not change shared cooldowns.",
   abilities={"Arcane Shot"},modifiers={["Arcane Shot"]=cooldown({0.3,0.6,0.9,1.2,1.5})},
  },
  {
   id="barrage",name="Barrage",tree="Marksmanship",maxRank=3,
   effect="Increases Multi-Shot, Aimed Shot and Volley damage by 5/10/15%.",
   abilities={"Multi-Shot","Aimed Shot","Volley"},
   modifiers={["Multi-Shot"]=pct({5,10,15}),
    ["Aimed Shot"]=pct({5,10,15}),Volley=pct({5,10,15})},
  },
  {
   id="savage_strikes",name="Savage Strikes",tree="Survival",maxRank=2,
   effect="Increases crit chance of all your melee abilities by 2/4 percentage points.",
   abilities={"Raptor Strike","Mongoose Bite","Wing Clip"},
   modifiers={["Raptor Strike"]=critical({2,4}),
    ["Mongoose Bite"]=critical({2,4}),["Wing Clip"]=critical({2,4})},
  },
  {
   id="improved_mend_pet",name="Improved Mend Pet",tree="Beast Mastery",maxRank=2,
   effect="Reduces Mend Pet mana cost by 10/20%; each heal tick can also cleanse a pet debuff.",
   abilities={"Mend Pet"},
   modifiers={["Mend Pet"]={kind="cost_pct",values={10,20},resource="MANA"}},
  },
 },
 -- https://talentsforever.com/paladin/talents (post 3 Nov hotfixes)
 PALADIN={
  {
   id="healing_light",name="Healing Light",tree="Holy",maxRank=3,
   effect="Increases Holy Light, Flash of Light and Holy Shock healing by 4/8/12%.",
   abilities={"Holy Light","Flash of Light","Holy Shock"},
   modifiers={["Holy Light"]={kind="healing_pct",values={4,8,12}},
    ["Flash of Light"]={kind="healing_pct",values={4,8,12}},
    ["Holy Shock"]={kind="healing_pct",values={4,8,12}}},
  },
  {
   id="benediction",name="Benediction",tree="Retribution",maxRank=5,
   effect="Reduces the mana cost of instant-cast spells and abilities by 2/4/6/8/10%.",
   abilities={"Judgement","Holy Shock","Hammer of Justice"},
   modifiers={Judgement={kind="cost_pct",values={2,4,6,8,10},resource="MANA"},
    ["Holy Shock"]={kind="cost_pct",values={2,4,6,8,10},resource="MANA"},
    ["Hammer of Justice"]={kind="cost_pct",values={2,4,6,8,10},resource="MANA"}},
  },
  {
   id="improved_judgement",name="Improved Judgement",tree="Retribution",maxRank=2,
   effect="Reduces Judgement cooldown by 1/2 sec.",
   abilities={"Judgement"},modifiers={Judgement=cooldown({1,2})},
  },
  {
   id="conviction",name="Conviction",tree="Retribution",maxRank=3,
   effect="Adds 2/4/6 percentage points crit chance to spells and attacks.",
   abilities={"Judgement","Holy Shock","Holy Strike","Hammer of Wrath"},
   modifiers={Judgement=critical({2,4,6}),["Holy Shock"]=critical({2,4,6}),
    ["Holy Strike"]=critical({2,4,6}),["Hammer of Wrath"]=critical({2,4,6})},
  },
  {
   id="improved_hammer_of_justice",name="Improved Hammer of Justice",tree="Protection",maxRank=3,
   effect="Reduces Hammer of Justice cooldown by 5/10/15 sec.",
   abilities={"Hammer of Justice"},
   modifiers={["Hammer of Justice"]=cooldown({5,10,15})},
  },
  {
   id="champion_of_the_light",name="Champion of the Light",tree="Retribution",maxRank=5,
   effect="Reduces Hammer of Wrath cast time by 0.2/0.4/0.6/0.8/1 sec. Spell damage scales with Intellect and is not simulated.",
   abilities={"Hammer of Wrath"},
   modifiers={["Hammer of Wrath"]={kind="cast_flat",values={0.2,0.4,0.6,0.8,1}}},
  },
 },
 ROGUE={
  {
   id="efficient_strikes",name="Efficient Strikes",tree="Combat",maxRank=2,
   effect="Reduces Sinister Strike and Hemorrhage Energy cost by 3/5.",
   abilities={"Sinister Strike","Hemorrhage"},
   modifiers={["Sinister Strike"]=cost({3,5},"ENERGY"),Hemorrhage=cost({3,5},"ENERGY")},
  },
  {
   id="coup_de_grace",name="Coup de Grace",tree="Combat",maxRank=3,
   effect="Increases Eviscerate damage and Death Mark damage/storage by 7/13/20%.",
   abilities={"Eviscerate","Death Mark"},
   modifiers={Eviscerate=pct({7,13,20}),["Death Mark"]=pct({7,13,20})},
  },
  {
   id="puncturing_wounds",name="Puncturing Wounds",tree="Combat",maxRank=3,
   effect="Backstab crit +10/20/30%, Mutilate crit +5/10/15%; Backstab may generate another combo point.",
   abilities={"Backstab","Mutilate"},
   modifiers={Backstab=critical({10,20,30}),Mutilate=critical({5,10,15})},
  },
  {
   id="flawless_execution",name="Flawless Execution",tree="Combat",maxRank=1,
   effect="Reduces Eviscerate Energy cost by 10.",
   abilities={"Eviscerate"},modifiers={Eviscerate=cost({10},"ENERGY")},
  },
  {
   id="aggression",name="Aggression",tree="Combat",maxRank=3,
   effect="Nov 2 revision: increases Sinister Strike and Eviscerate damage by 5/10/15%.",
   abilities={"Sinister Strike","Eviscerate"},
   modifiers={["Sinister Strike"]=pct({5,10,15}),Eviscerate=pct({5,10,15})},
  },
  {
   id="improved_ambush",name="Improved Ambush",tree="Subtlety",maxRank=3,
   effect="Increases Ambush critical strike chance by 15/30/45 percentage points.",
   abilities={"Ambush"},modifiers={Ambush=critical({15,30,45})},
  },
  {
   id="dirty_tricks",name="Dirty Tricks",tree="Subtlety",maxRank=2,
   effect="Reduces Sap and Blind Energy costs by 25/50%.",
   abilities={"Sap","Blind"},
   modifiers={Sap={kind="cost_pct",values={25,50},resource="ENERGY"},
     Blind={kind="cost_pct",values={25,50},resource="ENERGY"}},
  },
  {
   id="dirty_deeds",name="Dirty Deeds",tree="Subtlety",maxRank=2,
   effect="Reduces Cheap Shot and Garrote Energy by 10/20. Garrote no longer requires behind target.",
   abilities={"Cheap Shot","Garrote"},
   modifiers={["Cheap Shot"]=cost({10,20},"ENERGY"),Garrote=cost({10,20},"ENERGY")},
  },
  {
   id="elusiveness",name="Elusiveness",tree="Subtlety",maxRank=2,
   effect="Reduces cooldown on Vanish and Blind by 45/90 sec.",
   abilities={"Vanish","Blind"},
   modifiers={Vanish=cooldown({45,90}),Blind=cooldown({45,90})},
  },
  {
   id="improved_slice_and_dice",name="Improved Slice and Dice",tree="Assassination",maxRank=3,
   effect="Increases Slice and Dice duration by 15/30/45%.",
   abilities={"Slice and Dice"},modifiers={},
  },
 },
}

function S:GetTalentImpactCatalog(classToken)
 if classToken==nil and type(UnitClass)=="function" then
  local _,token=UnitClass("player")
  classToken=token
 end
 return self.TalentImpacts[classToken] or {}
end
function S:GetTalentImpactById(classToken,id)
 if type(id)~="string" then return nil end
 for _,entry in ipairs(self:GetTalentImpactCatalog(classToken)) do
  if entry.id==id then return entry end
 end
 return nil
end
function S:TalentAbilityIcon(name)
 if type(name)=="string" then
  if type(GetSpellTexture)=="function" then
   local ok,texture=pcall(GetSpellTexture,name)
   if ok and texture then return texture end
  end
  if C_Spell and type(C_Spell.GetSpellTexture)=="function" then
   local ok,texture=pcall(C_Spell.GetSpellTexture,name)
   if ok and texture then return texture end
  end
 end
 return "Interface\\Icons\\INV_Misc_QuestionMark"
end
