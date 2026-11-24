-- Pure mocked native Forever trait/spell reader; no live client claim.
SlashCmdList={}
InCombatLockdown=function()return false end
local class="DRUID"
UnitClass=function()return "Druid",class end
local registered={}
local hooks={}
CreateFrame=function()
 local f={}
 function f:RegisterEvent(name)
  if name=="NO_SUCH_EVENT" then error("unknown event") end
  registered[name]=true
 end
 function f:SetScript(name,fn)self[name]=fn end
 function f:HookScript(name,fn)self[name]=fn end
 return f
end
local ids={[8001]="Savage Fury",[8002]="Shredding Attacks",[8003]="Ferocity"}
C_Spell={
 GetSpellName=function(id)return ids[id]end,
 GetSpellPowerCost=function(id)
  if id==9001 then return {{name="ENERGY",cost=42,minCost=42}} end
  return nil
 end,
}
C_ClassTalents={GetActiveConfigID=function()return 42 end}
local pending=false
C_Traits={
 ConfigHasStagedChanges=function()return pending end,
 GetConfigInfo=function(id)assert(id==42);return {treeIDs={100}} end,
 GetTreeNodes=function(id)assert(id==100);return {10,20,30} end,
 GetNodeInfo=function(_,node)
  if node==10 then return {entryIDs={110},activeEntry={entryID=110,rank=2},activeRank=2} end
  if node==20 then return {entryIDs={120},activeEntry={entryID=120,rank=3},activeRank=3} end
  if node==30 then return {entryIDs={130},activeEntry={entryID=130,rank=0},activeRank=0} end
 end,
 GetEntryInfo=function(_,id)return {definitionID=id}end,
 GetDefinitionInfo=function(id)
  return {spellID=id==110 and 8001 or id==120 and 8002 or 8003}
 end,
}
local spells={
 {name="Shred",spellID=9000,subName="Rank 1",itemType=1,isPassive=false},
 {name="Shred",spellID=9001,subName="Rank 5",itemType=1,isPassive=false},
 {name="Claw",spellID=9002,subName="Rank 3",itemType=1,isPassive=false},
 {name="Swipe",spellID=9003,subName="Rank 2",itemType=1,isPassive=false},
 {name="Maul",spellID=9004,subName="Rank 1",itemType=1,isPassive=false},
 {name="Rake",spellID=9005,subName="Rank 1",itemType=1,isPassive=false},
 {name="Prowl",spellID=9006,subName="Rank 1",itemType=1,isPassive=false},
 {name="Passive Unknown",spellID=9999,subName="",itemType=1,isPassive=true},
}
C_SpellBook={
 GetNumSpellBookSkillLines=function()return 1 end,
 GetSpellBookSkillLineInfo=function()return {itemIndexOffset=0,numSpellBookItems=#spells}end,
 GetSpellBookItemInfo=function(i)return spells[i] end,
}
Enum={SpellBookItemType={Spell=1},SpellBookSpellBank={Player=0},TooltipDataType={Spell=1}}
TooltipDataProcessor={AddTooltipPostCall=function(kind,callback)
 assert(kind==1)
 hooks[#hooks+1]=callback
end}
GameTooltip=CreateFrame()
assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KSStealth/Stealth.lua"))()
assert(loadfile("addons/KSStealth/TalentImpactData.lua"))()
assert(loadfile("addons/KSStealth/TalentResolver.lua"))()
assert(loadfile("addons/KSStealth/TalentTooltip.lua"))()
KSStealth.BuildPage=function()end
KSStealth.BuildTalentPage=function()end
assert(loadfile("addons/KSStealth/Module.lua"))()
local S=KSStealth
assert(registered.TRAIT_CONFIG_UPDATED and registered.SPELLS_CHANGED)
local ranked,reason=S:ReadTalentRanks()
assert(ranked and not reason)
assert(ranked.ranks["Savage Fury"]==2)
assert(ranked.ranks["Shredding Attacks"]==3)
assert(ranked.found.Ferocity and ranked.ranks.Ferocity==0)
assert(not ranked.found["Rend and Tear"])
local learned=S:ReadLearnedAbilities()
assert(learned.Shred.spellID==9001 and learned.Shred.rank==5,
 "Must take highest known spell rank, not first rank")
assert(learned["Passive Unknown"]==nil)
assert(S:Store().talentImpactOverlay==false and S:Store().talentAnnotate==false)
assert(S:SetTalentImpactOverlay(true))
local okay,msg=S:RefreshTalentInsights()
assert(okay,msg)
assert(S:TrainedRank(S:GetTalentImpactById("DRUID","savage_fury"))==2)
assert(S:TrainedRank(S:GetTalentImpactById("DRUID","ferocity"))==0)
assert(S:TrainedRank(S:GetTalentImpactById("DRUID","rend_and_tear"))==nil)
local lines=S:AbilityInsightLines("Shred")
local combined=table.concat(lines,"\n")
assert(combined:find("100 -> 110",1,true),combined)
assert(combined:find("-18 ENERGY cost",1,true),combined)
assert(combined:find("current API 42",1,true),combined)
assert(combined:find("without talent approx. 60",1,true),combined)
assert(S:SetTalentImpactSetting("talentCritEstimate",true))
combined=table.concat(S:AbilityInsightLines("Shred"),"\n")
assert(combined:find("200% crit example: 220",1,true),combined)
assert(not S:SetTalentImpactSetting("unknownSetting",true))
assert(not S:SetTalentImpactSetting("talentAnnotate","yes"))
assert(S:SetTalentImpactSetting("talentAnnotate",true))
assert(S:CanAnnotateTalent())
assert(S:InstallTalentTooltipHook() and #hooks==1)
assert(S:InstallTalentTooltipHook() and #hooks==1,"hook once")
local tooltip={lines={}}
function tooltip:AddLine(line)self.lines[#self.lines+1]=line end
hooks[1](tooltip,{id=9001})
assert(#tooltip.lines>=2 and tooltip.lines[1]=="KS Talent Impacts (read-only)")
local count=#tooltip.lines
hooks[1](tooltip,{id=9001})
assert(#tooltip.lines==count,"must not append duplicate tooltip lines")
hooks[1](tooltip,{id=9999})
assert(#tooltip.lines==count,"untrained talents cannot assert live modifier")
-- Synthetic rank snapshots verify the new typed display rules without
-- inventing any combat damage or requiring active talents on this character.
local function snapshotFor(token,rankMap)
 class=token
 local found={}
 for name,_ in pairs(rankMap) do found[name]=true end
 S.talentSnapshot={class=token,talents={found=found,ranks=rankMap},abilities={}}
end
snapshotFor("SHAMAN",{
 ["Convection"]=5,["Concussion"]=5,["Elemental Alacrity"]=3,
})
local shock=table.concat(S:AbilityInsightLines("Lightning Bolt")," | ")
assert(shock:find("-10% MANA cost",1,true),shock)
assert(shock:find("-0.5 sec cast time",1,true),shock)
assert(shock:find("+5% damage",1,true),shock)
snapshotFor("MAGE",{Accelerant=5,Incineration=5,Shatter=3,["Arcane Geometry"]=2})
local mage=table.concat(S:AbilityInsightLines("Fireball")," | ")
assert(mage:find("-0.5 sec cast time",1,true),mage)
local ice=table.concat(S:AbilityInsightLines("Ice Lance")," | ")
assert(ice:find("+10 percentage points crit chance",1,true),ice)
assert(not ice:find("Shatter",1,true),
 "conditional Frozen-target crit must not be advertised as unconditional")
local range=table.concat(S:AbilityInsightLines("Arcane Blast")," | ")
assert(range:find("+6 yards range",1,true),range)
snapshotFor("HUNTER",{["Improved Stings"]=3,Efficiency=5,Barrage=3})
local sting=table.concat(S:AbilityInsightLines("Serpent Sting")," | ")
assert(sting:find("+20% damage",1,true) and sting:find("-15% MANA cost",1,true),sting)
local duration=table.concat(S:AbilityInsightLines("Scorpid Sting")," | ")
assert(duration:find("+45 sec duration",1,true),duration)
local cooldown=table.concat(S:AbilityInsightLines("Viper Sting")," | ")
assert(cooldown:find("-6 sec cooldown",1,true),cooldown)
snapshotFor("PALADIN",{["Healing Light"]=3,["Improved Judgement"]=2,
 ["Champion of the Light"]=5,Conviction=3})
local heals=table.concat(S:AbilityInsightLines("Holy Light")," | ")
assert(heals:find("+12% healing (normalized 100 -> 112)",1,true),heals)
local judgement=table.concat(S:AbilityInsightLines("Judgement")," | ")
assert(judgement:find("-2 sec cooldown",1,true),judgement)
local hammer=table.concat(S:AbilityInsightLines("Hammer of Wrath")," | ")
assert(hammer:find("-1 sec cast time",1,true),hammer)
assert(#S:AbilityInsightLines("Frostbolt")==0,"no cross-class modifier leakage")
class="DRUID"
S.talentSnapshot=nil
pending=true
local no,why=S:ReadTalentRanks()
assert(no==nil and why:find("Pending"))
pending=false
S.talentSnapshot=nil
assert(#S:AbilityInsightLines("Shred")==0,"no stale calculations")
InCombatLockdown=function()return true end
local blocked=S:RefreshTalentInsights()
assert(not blocked and not S:CanAnnotateTalent())
assert(#S:AbilityInsightLines("Shred")==0)
assert(not S:SetTalentImpactSetting("talentCritEstimate",false))
InCombatLockdown=function()return false end
C_Traits.GetConfigInfo=function()return nil end
local unavailable=S:ReadTalentRanks()
assert(unavailable==nil,"missing Forever API must fail closed")
assert(KoolSupportDB.modules.ks_stealth.talentAnnotate and
 KoolSupportDB.modules.ks_stealth.talentCritEstimate)
print("PASS talent resolver: six class modifiers, rank scans, source-safe cost/cast/heal data, tooltips and no combat reads")
