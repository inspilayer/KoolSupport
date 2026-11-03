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
