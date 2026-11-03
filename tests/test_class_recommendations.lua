-- Class recommendations: nine Forever classes, names/body limits, native icons and no focus coupling.
SlashCmdList={}
InCombatLockdown=function()return false end
KoolSupportDB={}
local player="DRUID"
UnitClass=function()return "Player",player end
assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KSMacros/Engine.lua"))()
assert(loadfile("addons/KSMacros/ClassPresets.lua"))()
assert(loadfile("addons/KSMacros/Suite.lua"))()
local M=KSMacros
local classes={"DRUID","HUNTER","MAGE","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR"}
local all={}
local total=0
for _,class in ipairs(classes) do
  player=class
  assert(M:CurrentClass()==class)
  local entries=M:GetRecommended()
  assert(#entries>=5,"Missing class starter catalog: "..class)
  for _,item in ipairs(entries) do
    assert(not all[item.id],"Macro id collision: "..item.id)
    all[item.id]=true
    assert(item.recommended and item.group and item.note)
    assert(item.body:sub(1,12)=="#showtooltip")
    assert(item.body:find("/cast",1,true) or item.body:find("/petpassive",1,true))
    assert(not item.body:find("@focus",1,true),"Class starter must not require a focus supportee")
    assert(M:Validate(item.id,M:NormalizeTooltip(item.body)),item.id.." exceeds macro limits")
    assert(M:ClassIconCoords(class),"Missing icon atlas: "..class)
    total=total+1
  end
  local suite=M:GetSuite()
  assert(suite[1].id==entries[1].id,"Recommendations should be the first tab")
  assert(#suite>=#entries+7,"Generic templates must remain")
end
assert(total==45)
assert(#M:GetRecommended("DEATHKNIGHT")==0)
player="PRIEST"
local renew
for _,v in ipairs(M:GetRecommended()) do if v.spell=="Renew" then renew=v end end
assert(renew)
assert(M:RecommendationAvailability(renew,nil)==nil,"Unknown spellbook cannot silently claim learned")
local ok,reason=M:RecommendationAvailability(renew,{})
assert(ok==false and reason:find("Not learned"))
assert(M:RecommendationAvailability(renew,{Renew=true})==true)
local first=M:GetRecommended()[1]
C_Spell={GetSpellTexture=function(id)assert(id==123);return 456 end}
assert(M:RecommendationIcon(first,{[first.spell]={spellID=123}})==456)
assert(M:RecommendationIcon(first,{})==nil)
player="ROGUE"
local manual
for _,v in ipairs(M:GetRecommended()) do if v.id=="KSR-R-Fin" then manual=v end end
assert(manual and #manual.requires==2 and manual.body:find("mod:shift",1,true))
assert(not M:RecommendationAvailability(manual,{["Sinister Strike"]=true}))
assert(M:RecommendationAvailability(manual,{["Sinister Strike"]=true,["Eviscerate"]=true}))
print("PASS class macro catalog: nine classes, 45 optional presets, learned gating, icons, no focus")
