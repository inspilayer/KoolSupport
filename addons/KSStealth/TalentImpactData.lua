-- KS Stealth: read-only Forever talent-to-ability catalog.
-- This is NOT a talent scanner or a damage calculator. Entries are curated
-- from talent tooltips / Blizzard development notes as of 2026-11-02.
-- In-client validation is pending. Never assert an entry is learned or ranked.
KSStealth=KSStealth or {}
local S=KSStealth

S.TalentImpacts={
  DRUID={
    {
      id="ferocity",name="Ferocity",tree="Feral Combat",maxRank=5,
      effect="Reduces Rage or Energy costs by 1 per rank (up to 5).",
      abilities={"Maul","Primal Bite","Swipe","Claw","Rake"},
    },
    {
      id="shredding_attacks",name="Shredding Attacks",tree="Feral Combat",maxRank=3,
      effect="Reduces Shred Energy by 6 and Lacerate Rage by 1 per rank.",
      abilities={"Shred","Lacerate"},
    },
    {
      id="savage_fury",name="Savage Fury",tree="Feral Combat",maxRank=2,
      effect="Increases affected ability damage by 5% per rank (up to 10%).",
      abilities={"Claw","Rake","Shred","Maul","Swipe"},
    },
  },
  ROGUE={
    {
      id="efficient_strikes",name="Efficient Strikes",tree="Combat",maxRank=2,
      effect="Reduces Energy cost by 3 (rank 1) or 5 (rank 2). Formerly Improved Sinister Strike.",
      abilities={"Sinister Strike","Hemorrhage"},
    },
    {
      id="coup_de_grace",name="Coup de Grace",tree="Combat",maxRank=3,
      effect="Increases Eviscerate damage and Death Mark damage/storage by 7/13/20%. Formerly Improved Eviscerate.",
      abilities={"Eviscerate","Death Mark"},
    },
    {
      id="puncturing_wounds",name="Puncturing Wounds",tree="Combat",maxRank=3,
      effect="Increases Backstab/Mutilate critical chance and Backstab bonus combo point chance.",
      abilities={"Backstab","Mutilate"},
    },
    {
      id="flawless_execution",name="Flawless Execution",tree="Combat",maxRank=1,
      effect="Reduces Eviscerate's Energy cost by 15.",
      abilities={"Eviscerate"},
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
