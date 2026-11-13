-- Read-only five-module readiness checks with default/missing/unavailable API paths.
SlashCmdList={}
local saved={customPreserved={safely=true}}
KoolSupportDB=saved
InCombatLockdown=function() return false end
local toc=16001
GetBuildInfo=function()return "11.2",12345,"Nov 3",toc end
local loaded={
 KoolSupport=true,KSMacros=true,KSSupportSessions=true,KSStealth=true,KSAfflictions=false,KSCampfireChat=true,KSThreat=true,
}
C_AddOns={IsAddOnLoaded=function(name)return loaded[name] or false end}
C_SpellBook={GetNumSpellBookSkillLines=function()end,GetSpellBookItemInfo=function()end}
C_Traits={GetNodeInfo=function()end}
C_ClassTalents={GetActiveConfigID=function()end}
C_NamePlate={GetNamePlates=function()end,GetNamePlateForUnit=function()end}
GetComboPoints=function()error("readiness must not sample combat values")end
Enum={TooltipDataType={Spell=1}}
TooltipDataProcessor={AddTooltipPostCall=function()end}
local labels,buttons={},{}
local function frame()
 local f={}
 function f:CreateFontString()
  local text=frame()
  labels[#labels+1]=text
  return text
 end
 function f:SetSize()end
 function f:SetPoint()end
 function f:SetWidth()end
 function f:SetJustifyH()end
 function f:SetText(t)self.text=t end
 function f:SetScript(key,cb)self[key]=cb end
 return f
end
CreateFrame=function()local f=frame();buttons[#buttons+1]=f;return f end

assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KoolSupport/Diagnostics.lua"))()
assert(loadfile("addons/KoolSupport/UI.lua"))()
local KS=KoolSupport
assert(KS.VERSION=="0.10.7-rc.1")
KS:RegisterModule({id="ks_macros",title="KS Macros",apiVersion=1,defaultEnabled=true})
KS:RegisterModule({id="ks_support_sessions",title="KS Support Sessions",apiVersion=1,defaultEnabled=true,requires={"ks_macros"}})
KS:RegisterModule({id="ks_stealth",title="KS Stealth",apiVersion=1,defaultEnabled=true})
KS:RegisterModule({id="ks_afflictions",title="KS Afflictions",apiVersion=1,defaultEnabled=true})
KS:RegisterModule({id="ks_campfire_chat",title="Campfire Chat",apiVersion=1,defaultEnabled=true})
KS:RegisterModule({id="ks_threat",title="KS Threat",apiVersion=1,defaultEnabled=false})
local rows=KS:CollectLaunchChecks()
assert(#rows==13,"build + 7 addons + 5 capability checks")
local map={}
for _,r in ipairs(rows)do map[r.id]=r end
assert(map.interface.status=="MATCH")
assert(map.KoolSupport.status=="ENABLED","base must not require module registry")
assert(map.KSMacros.status=="ENABLED")
assert(map.KSAfflictions.status=="MISSING")
assert(map.KSCampfireChat.status=="ENABLED")
assert(map.KSThreat.status=="OFF")
assert(map.traits.status=="PRESENT")
assert(map.spellbook.status=="PRESENT")
assert(map.tooltip.status=="PRESENT")
assert(map.combos.status=="PRESENT")
assert(map.nameplates.status=="PRESENT")
assert(saved.customPreserved.safely)
assert(not saved.modules or not saved.modules.ks_stealth,"diagnostics must not write feature preferences")
assert(KS:SetModuleEnabled("ks_stealth",false))
rows=KS:CollectLaunchChecks()
for _,r in ipairs(rows)do if r.id=="KSStealth" then assert(r.status=="OFF")end end
toc=16005
rows=KS:CollectLaunchChecks()
assert(rows[1].status=="REVIEW" and rows[1].detail:find("16005",1,true))
C_SpellBook=nil
rows=KS:CollectLaunchChecks()
for _,r in ipairs(rows)do if r.id=="spellbook" then assert(r.status=="UNAVAILABLE") end end
-- API detection does not read any combat resources, even in combat.
InCombatLockdown=function()return true end
assert(#KS:CollectLaunchChecks()==13)
assert(KS:CanOpenPage("launch_checks"))
local parent=frame()
KS.pages.launch_checks.build(parent)
local heading=false
for _,l in ipairs(labels)do
 if l.text and l.text:find("Launch Checks",1,true) then heading=true end
end
assert(heading,"launch checks page must be renderable")
assert(saved.customPreserved.safely,"original data never overwritten")
print("PASS launch checks: five addon states, API signals, UI render, combat-read avoidance")
